------------------------------------------------------------------------------
--
--  LGI Object handling.
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local pairs, select, setmetatable, error = pairs, select, setmetatable, error

local core = require 'lgi.core'
local gi = core.gi
local repo = core.repo

local Value = repo.GObject.Value
local Type = repo.GObject.Type
local Closure = repo.GObject.Closure

local Object = repo.GObject.Object

-- Object constructor, 'param' contains table with properties/signals
-- to initialize.
local parameter_info = gi.GObject.Parameter
local object_new = gi.GObject.Object.methods.new
if object_new then
   object_new = core.callable.new(object_new)
else
   -- Unfortunately, older GI (<1.30) does not export g_object_newv()
   -- in the typelib, so we have to workaround here with manually
   -- implemented C version.
   object_new = core.object.new
end
function Object:_new(args)
   -- Process 'args' table, separate properties from other fields.
   local params, others, safe = {}, {}, {}
   for name, arg in pairs(args or {}) do
      local argtype = self[name]
      if gi.isinfo(argtype) and argtype.is_property then
	 local param = core.record.new(parameter_info)
	 name = argtype.name

	 -- Store the name string in some safe Lua place ('safe'
	 -- table), because param is GParameter, which contains only
	 -- non-owning pointer to the string, and it could be
	 -- Lua-GC'ed while still referenced by GParameter instance.
	 safe[#safe + 1] = name

	 param.name = name
	 local gtype = Type.from_typeinfo(argtype.typeinfo)
	 Value.init(param.value, gtype)
	 local marshaller = Value.find_marshaller(gtype, argtype.typeinfo)
	 marshaller(param.value, nil, arg)
	 params[#params + 1] = param
      else
	 others[name] = arg
      end
   end

   -- Create the object.
   local object = object_new(self._gtype, params)

   -- Attach arguments previously filtered out from creation.
   for name, func in pairs(others) do object[name] = func end
   return object
end

-- Initially unowned creation is similar to normal GObject creation,
-- but we have to ref_sink newly created object.
local InitiallyUnowned = repo.GObject.InitiallyUnowned
function InitiallyUnowned:_new(args)
   local object = Object._new(self, args)
   return Object.ref_sink(object)
end

-- Reading 'class' yields real instance of the object class.
Object._attribute = { class = {} }
function Object._attribute.class:get()
   return core.object.query(self, 'class')
end

-- Custom _element implementation, checks dynamically inherited
-- interfaces and dynamic properties.
local inherited_element = Object._element
function Object:_element(object, name)
   local element, category = inherited_element(self, object, name)
   if element then return element, category end

   -- Everything else works only if we have object instance.
   if not object then return nil end

   -- List all interfaces implemented by this object and try whether
   -- they can handle specified _element request.
   local interfaces = Type.interfaces(core.object.query(object, 'gtype'))
   for i = 1, #interfaces do
      local info = gi[core.gtype(interfaces[i])]
      local iface = repo[info.namespace][info.name]
      if iface then element, category = iface:_element(object, name) end
      if element then return element, category end
   end

   -- Element not found in the repo (typelib), try whether dynamic
   -- property of the specified name exists.
   local class = core.record.cast(core.object.query(object, 'class'),
				  Object._class)
   local property = Object._class.find_property(class, name:gsub('_', '%-'))
   if property then return property, '_paramspec' end
end

-- Sets/gets property using specified marshaller attributes.
local function marshal_property(obj, name, flags, gtype, marshaller, ...)
   -- Check access rights of the property.
   local mode = select('#', ...) > 0 and 'WRITABLE' or 'READABLE'
   if not core.has_bit(flags, repo.GObject.ParamFlags[mode]) then
      error(("%s: `%s' not %s"):format(core.object.query(obj, 'repo')._name,
				       name, mode:lower()))
   end
   local value = Value(gtype)
   if mode == 'WRITABLE' then
      marshaller(value, nil, ...)
      Object.set_property(obj, name, value)
   else
      Object.get_property(obj, name, value)
      return marshaller(value)
   end
end

-- GI property accessor.
function Object:_access_property(object, property, ...)
   local typeinfo = property.typeinfo
   local gtype = Type.from_typeinfo(typeinfo)
   local marshaller = Value.find_marshaller(gtype, typeinfo, property.transfer)
   return marshal_property(object, property.name, property.flags,
			   gtype, marshaller, ...)
end

-- GLib property accessor (paramspec).
function Object:_access_paramspec(object, pspec, ...)
   return marshal_property(object, pspec.name, pspec.flags, pspec.value_type,
			   Value.find_marshaller(pspec.value_type), ...)
end

local quark_from_string = repo.GLib.quark_from_string
local signal_lookup = repo.GObject.signal_lookup
local signal_connect_closure_by_id = repo.GObject.signal_connect_closure_by_id
local signal_emitv = repo.GObject.signal_emitv
-- Connects signal to specified object instance.
local function connect_signal(obj, gtype, name, closure, detail, after)
   return signal_connect_closure_by_id(
      obj, signal_lookup(name, gtype),
      detail and quark_from_string(detail) or 0,
      closure, after or false)
end
-- Emits signal on specified object instance.
local function emit_signal(obj, gtype, info, detail, ...)
   -- Compile callable info.
   local call_info = Closure.CallInfo.new(info)

   -- Marshal input arguments.
   local retval, params, keepalive = call_info:pre_call(obj, ...)

   -- Invoke the signal.
   signal_emitv(params, signal_lookup(info.name, gtype),
		detail and quark_from_string(detail) or 0, retval)

   -- Unmarshal results.
   return call_info:post_call(params, retval)
end

-- Signal accessor.
function Object:_access_signal(object, info, ...)
   local gtype = self._gtype
   if select('#', ...) > 0 then
      -- Assignment means 'connect signal without detail'.
      connect_signal(object, gtype, info.name, Closure((...), info))
   else
      -- Reading yields table with signal operations.
      local pad = {}
      function pad:connect(target, detail, after)
	 return connect_signal(object, gtype, info.name,
			       Closure(target, info), detail, after)
      end
      function pad:emit(detail, ...)
	 return emit_signal(object, gtype, info, detail, object, ...)
      end

      -- If signal supports details, add metatable implementing
      -- __newindex for connecting in the 'on_signal['detail'] =
      -- handler' form.
      if not info.is_signal or info.flags.detailed then
	 local mt = {}
	 function mt:__newindex(detail, target)
	    connect_signal(object, gtype, info.name, Closure(target, info),
			   detail)
	 end
	 setmetatable(pad, mt)
      end

      -- Return created signal pad.
      return pad
   end
end

-- GOI<1.30 does not export 'Object.on_notify' signal from the
-- typelib.  Work-around this problem by implementing custom on_notify
-- attribute.
if not gi.GObject.Object.signals.notify then
   local notify_info = gi.GObject.ObjectClass.fields.notify.typeinfo.interface
   function Object._attribute.on_notify(object, ...)
      local repotable = core.object.query(object, 'repo')
      return Object._access_signal(repotable, object, notify_info, ...)
   end
end

-- Bind property implementation.  For some strange reason, GoI<1.30
-- exports it only on GInitiallyUnowned and not on GObject.  Oh
-- well...
for _, name in pairs { 'bind_property', 'bind_property_full' } do
   if not Object[name] then
      Object._method[name] = InitiallyUnowned[name]
   end
end
