--[[--------------------------------------------------------------------------

  LGI core testsuite.

  Copyright (c) 2010, 2011 Pavel Holejsovsky
  Licensed under the MIT license:
  http://www.opensource.org/licenses/mit-license.php

--]]--------------------------------------------------------------------------

local lgi = require 'lgi'
local GLib = lgi.GLib
local Gio = lgi.Gio
local GObject = lgi.GObject
local bytes = require 'bytes'

-- Make logs verbose (do not mute DEBUG level).
lgi.log.DEBUG = 'verbose'

-- Testing infrastructure.
local testgroup = { reverse_index = {} }
testgroup.__index = testgroup

-- Creates new named testgroup.
function testgroup.new(name)
   return setmetatable({ name = name, results = { total = 0, failed = 0 } },
		       testgroup)
end

-- Adds new test.
function testgroup:__newindex(name, func)
   rawset(self, name, func)
   rawset(self, #self + 1, name)
   self.reverse_index[name] = #self
end

-- Runs specified test(s), either by numeric id or by regexp mask.
function testgroup:run(id)
   local function runfunc(num)
      self.results.total = self.results.total + 1
      io.write(('%-8s:%3d:%-35s'):format(self.name, num, self[num]))
      local ok, msg
      local func = self[self[num]]
      if self.debug then func() ok = true else
	 ok, msg = pcall(func)
      end
      collectgarbage()
      if not ok then
	 self.results.failed = self.results.failed + 1
	 io.write('FAIL:' .. tostring(msg) .. '\n')
	 return
      end
      io.write('PASS\n')
   end

   id = id or ''
   self.results.total = 0
   self.results.failed = 0
   if type(id) == 'number' then
      runfunc(id)
   else
      for i = 1, #self do
	 if self[i] ~= 'debug' and self[i]:match(id) then runfunc(i) end
      end
      if (self.results.failed == 0) then
	 io.write(('%s: all %d tests passed.\n'):format(
		     self.name, self.results.total))
      else
	 io.write(('%s: %d of %d tests FAILED!\n'):format(
		     self.name, self.results.failed, self.results.total))
      end
   end
end

-- Fails given test with error, number indicates how many functions on
-- the stack should be skipped when reporting error location.
local function fail(msg, skip)
   error(msg or 'failure', (skip or 1) + 1)
end
local function check(cond, msg, skip)
   if not cond then fail(msg, (skip or 1) + 1) end
end

-- Helper, checks that given value has requested type and value.
local function checkv(val, exp, exptype)
   check(type(val) == exptype, string.format("got type `%s', expected `%s'",
					     type(val), exptype), 2)
   check(val == exp, string.format("got value `%s', expected `%s'",
				   tostring(val), tostring(exp)), 2)
end

-- gobject-introspection 'Regress' based tests.
local gireg = testgroup.new('gireg')

function gireg.type_boolean()
   local R = lgi.Regress
   checkv(R.test_boolean(true), true, 'boolean')
   checkv(R.test_boolean(false), false, 'boolean')
   check(select('#', R.test_boolean(true)) == 1)
   check(select('#', R.test_boolean(false)) == 1)
   check(not pcall(R.test_boolean))
   check(not pcall(R.test_boolean, nil))
   checkv(R.test_boolean(0), true, 'boolean')
   checkv(R.test_boolean(1), true, 'boolean')
   checkv(R.test_boolean('string'), true, 'boolean')
   checkv(R.test_boolean({}), true, 'boolean')
   checkv(R.test_boolean(function() end), true, 'boolean')
end

function gireg.type_int8()
   local R = lgi.Regress
   checkv(R.test_int8(0), 0, 'number')
   checkv(R.test_int8(1), 1, 'number')
   checkv(R.test_int8(-1), -1, 'number')
   checkv(R.test_int8(1.1), 1, 'number')
   checkv(R.test_int8(-1.1), -1, 'number')
   checkv(R.test_int8(0x7f), 0x7f, 'number')
   checkv(R.test_int8(-0x80), -0x80, 'number')
   check(not pcall(R.test_int8, 0x80))
   check(not pcall(R.test_int8, -0x81))
   check(not pcall(R.test_int8))
   check(not pcall(R.test_int8, nil))
   check(not pcall(R.test_int8, 'string'))
   check(not pcall(R.test_int8, true))
   check(not pcall(R.test_int8, {}))
   check(not pcall(R.test_int8, function() end))
end

function gireg.type_uint8()
   local R = lgi.Regress
   checkv(R.test_uint8(0), 0, 'number')
   checkv(R.test_uint8(1), 1, 'number')
   checkv(R.test_uint8(1.1), 1, 'number')
   checkv(R.test_uint8(0xff), 0xff, 'number')
   check(not pcall(R.test_uint8, 0x100))
   check(not pcall(R.test_uint8, -1))
   check(not pcall(R.test_uint8))
   check(not pcall(R.test_uint8, nil))
   check(not pcall(R.test_uint8, 'string'))
   check(not pcall(R.test_uint8, true))
   check(not pcall(R.test_uint8, {}))
   check(not pcall(R.test_uint8, function() end))
end

function gireg.type_int16()
   local R = lgi.Regress
   checkv(R.test_int16(0), 0, 'number')
   checkv(R.test_int16(1), 1, 'number')
   checkv(R.test_int16(-1), -1, 'number')
   checkv(R.test_int16(1.1), 1, 'number')
   checkv(R.test_int16(-1.1), -1, 'number')
   checkv(R.test_int16(0x7fff), 0x7fff, 'number')
   checkv(R.test_int16(-0x8000), -0x8000, 'number')
   check(not pcall(R.test_int16, 0x8000))
   check(not pcall(R.test_int16, -0x8001))
   check(not pcall(R.test_int16))
   check(not pcall(R.test_int16, nil))
   check(not pcall(R.test_int16, 'string'))
   check(not pcall(R.test_int16, true))
   check(not pcall(R.test_int16, {}))
   check(not pcall(R.test_int16, function() end))
end

function gireg.type_uint16()
   local R = lgi.Regress
   checkv(R.test_uint16(0), 0, 'number')
   checkv(R.test_uint16(1), 1, 'number')
   checkv(R.test_uint16(1.1), 1, 'number')
   checkv(R.test_uint16(0xffff), 0xffff, 'number')
   check(not pcall(R.test_uint16, 0x10000))
   check(not pcall(R.test_uint16, -1))
   check(not pcall(R.test_uint16))
   check(not pcall(R.test_uint16, nil))
   check(not pcall(R.test_uint16, 'string'))
   check(not pcall(R.test_uint16, true))
   check(not pcall(R.test_uint16, {}))
   check(not pcall(R.test_uint16, function() end))
end

function gireg.type_int32()
   local R = lgi.Regress
   checkv(R.test_int32(0), 0, 'number')
   checkv(R.test_int32(1), 1, 'number')
   checkv(R.test_int32(-1), -1, 'number')
   checkv(R.test_int32(1.1), 1, 'number')
   checkv(R.test_int32(-1.1), -1, 'number')
   checkv(R.test_int32(0x7fffffff), 0x7fffffff, 'number')
   checkv(R.test_int32(-0x80000000), -0x80000000, 'number')
   check(not pcall(R.test_int32, 0x80000000))
   check(not pcall(R.test_int32, -0x80000001))
   check(not pcall(R.test_int32))
   check(not pcall(R.test_int32, nil))
   check(not pcall(R.test_int32, 'string'))
   check(not pcall(R.test_int32, true))
   check(not pcall(R.test_int32, {}))
   check(not pcall(R.test_int32, function() end))
end

function gireg.type_uint32()
   local R = lgi.Regress
   checkv(R.test_uint32(0), 0, 'number')
   checkv(R.test_uint32(1), 1, 'number')
   checkv(R.test_uint32(1.1), 1, 'number')
   checkv(R.test_uint32(0xffffffff), 0xffffffff, 'number')
   check(not pcall(R.test_uint32, 0x100000000))
   check(not pcall(R.test_uint32, -1))
   check(not pcall(R.test_uint32))
   check(not pcall(R.test_uint32, nil))
   check(not pcall(R.test_uint32, 'string'))
   check(not pcall(R.test_uint32, true))
   check(not pcall(R.test_uint32, {}))
   check(not pcall(R.test_uint32, function() end))
end

function gireg.type_int64()
   local R = lgi.Regress
   checkv(R.test_int64(0), 0, 'number')
   checkv(R.test_int64(1), 1, 'number')
   checkv(R.test_int64(-1), -1, 'number')
   checkv(R.test_int64(1.1), 1, 'number')
   checkv(R.test_int64(-1.1), -1, 'number')
   check(not pcall(R.test_int64))
   check(not pcall(R.test_int64, nil))
   check(not pcall(R.test_int64, 'string'))
   check(not pcall(R.test_int64, true))
   check(not pcall(R.test_int64, {}))
   check(not pcall(R.test_int64, function() end))

-- Following tests fail because Lua's internal number representation
-- is always 'double', and conversion between double and int64 big
-- constants is always lossy.  Not sure if it can be solved somehow.

--   checkv(R.test_int64(0x7fffffffffffffff), 0x7fffffffffffffff, 'number')
--   checkv(R.test_int64(-0x8000000000000000), -0x8000000000000000, 'number')
--   check(not pcall(R.test_int64, 0x8000000000000000))
--   check(not pcall(R.test_int64, -0x8000000000000001))

end

function gireg.type_uint64()
   local R = lgi.Regress
   checkv(R.test_uint64(0), 0, 'number')
   checkv(R.test_uint64(1), 1, 'number')
   checkv(R.test_uint64(1.1), 1, 'number')
   check(not pcall(R.test_uint64, -1))
   check(not pcall(R.test_uint64))
   check(not pcall(R.test_uint64, nil))
   check(not pcall(R.test_uint64, 'string'))
   check(not pcall(R.test_uint64, true))
   check(not pcall(R.test_uint64, {}))
   check(not pcall(R.test_uint64, function() end))

-- See comment above about lossy conversions.

--   checkv(R.test_uint64(0xffffffffffffffff), 0xffffffffffffffff, 'number')
--   check(not pcall(R.test_uint64, 0x10000000000000000))
end

function gireg.type_short()
   local R = lgi.Regress
   checkv(R.test_short(0), 0, 'number')
   checkv(R.test_short(1), 1, 'number')
   checkv(R.test_short(-1), -1, 'number')
   checkv(R.test_short(1.1), 1, 'number')
   checkv(R.test_short(-1.1), -1, 'number')
end

function gireg.type_ushort()
   local R = lgi.Regress
   checkv(R.test_ushort(0), 0, 'number')
   checkv(R.test_ushort(1), 1, 'number')
   checkv(R.test_ushort(1.1), 1, 'number')
   check(not pcall(R.test_ushort, -1))
end

function gireg.type_int()
   local R = lgi.Regress
   checkv(R.test_int(0), 0, 'number')
   checkv(R.test_int(1), 1, 'number')
   checkv(R.test_int(-1), -1, 'number')
   checkv(R.test_int(1.1), 1, 'number')
   checkv(R.test_int(-1.1), -1, 'number')
end

function gireg.type_uint()
   local R = lgi.Regress
   checkv(R.test_uint(0), 0, 'number')
   checkv(R.test_uint(1), 1, 'number')
   checkv(R.test_uint(1.1), 1, 'number')
   check(not pcall(R.test_uint, -1))
end

function gireg.type_ssize()
   local R = lgi.Regress
   checkv(R.test_ssize(0), 0, 'number')
   checkv(R.test_ssize(1), 1, 'number')
   checkv(R.test_ssize(-1), -1, 'number')
   checkv(R.test_ssize(1.1), 1, 'number')
   checkv(R.test_ssize(-1.1), -1, 'number')
end

function gireg.type_size()
   local R = lgi.Regress
   checkv(R.test_size(0), 0, 'number')
   checkv(R.test_size(1), 1, 'number')
   checkv(R.test_size(1.1), 1, 'number')
   check(not pcall(R.test_size, -1))
end

-- Helper, checks that given value has requested type and value, with some
-- tolerance because of low precision of gfloat type.
local function checkvf(val, exp, tolerance)
   check(type(val) == 'number', string.format(
	     "got type `%s', expected `number'", type(val)), 2)
   check(math.abs(val - exp) <= tolerance,
	  string.format("got value `%s', expected `%s'",
			tostring(val), tostring(exp)), 2)
end

function gireg.type_float()
   local R = lgi.Regress
   local t = 0.0000001
   checkvf(R.test_float(0), 0, t)
   checkvf(R.test_float(1), 1, t)
   checkvf(R.test_float(1.1), 1.1, t)
   checkvf(R.test_float(-1), -1, t)
   checkvf(R.test_float(-1.1), -1.1, t)
   checkvf(R.test_float(0x8000), 0x8000, t)
   checkvf(R.test_float(0xffff), 0xffff, t)
   checkvf(R.test_float(-0x8000), -0x8000, t)
   checkvf(R.test_float(-0xffff), -0xffff, t)
   check(not pcall(R.test_float))
   check(not pcall(R.test_float, nil))
   check(not pcall(R.test_float, 'string'))
   check(not pcall(R.test_float, true))
   check(not pcall(R.test_float, {}))
   check(not pcall(R.test_float, function() end))
end

function gireg.type_double()
   local R = lgi.Regress
   checkv(R.test_double(0), 0, 'number')
   checkv(R.test_double(1), 1, 'number')
   checkv(R.test_double(1.1), 1.1, 'number')
   checkv(R.test_double(-1), -1, 'number')
   checkv(R.test_double(-1.1), -1.1, 'number')
   checkv(R.test_double(0x80000000), 0x80000000, 'number')
   checkv(R.test_double(0xffffffff), 0xffffffff, 'number')
   checkv(R.test_double(-0x80000000), -0x80000000, 'number')
   checkv(R.test_double(-0xffffffff), -0xffffffff, 'number')
   check(not pcall(R.test_double))
   check(not pcall(R.test_double, nil))
   check(not pcall(R.test_double, 'string'))
   check(not pcall(R.test_double, true))
   check(not pcall(R.test_double, {}))
   check(not pcall(R.test_double, function() end))
end

function gireg.type_timet()
   local R = lgi.Regress
   checkv(R.test_timet(0), 0, 'number')
   checkv(R.test_timet(1), 1, 'number')
   checkv(R.test_timet(10000), 10000, 'number')
   check(not pcall(R.test_timet))
   check(not pcall(R.test_timet, nil))
   check(not pcall(R.test_timet, 'string'))
   check(not pcall(R.test_timet, true))
   check(not pcall(R.test_timet, {}))
   check(not pcall(R.test_timet, function() end))
end

function gireg.type_gtype()
   local R = lgi.Regress
   checkv(R.test_gtype(), nil, 'nil')
   checkv(R.test_gtype(nil), nil, 'nil')
   checkv(R.test_gtype(0), nil, 'nil')
   checkv(R.test_gtype('void'), 'void', 'string')
   checkv(R.test_gtype(4), 'void', 'string')
   checkv(R.test_gtype('GObject'), 'GObject', 'string')
   checkv(R.test_gtype(80), 'GObject', 'string')
   checkv(R.test_gtype(R.TestObj), 'RegressTestObj', 'string')
   check(not pcall(R.test_gtype, true))
   check(not pcall(R.test_gtype, function() end))
end

function gireg.utf8_const_return()
   local R = lgi.Regress
   local utf8_const = 'const \226\153\165 utf8'
   check(R.test_utf8_const_return() == utf8_const)
end

function gireg.utf8_nonconst_return()
   local R = lgi.Regress
   local utf8_nonconst = 'nonconst \226\153\165 utf8'
   check(R.test_utf8_nonconst_return() == utf8_nonconst)
end

function gireg.utf8_const_in()
   local R = lgi.Regress
   local utf8_const = 'const \226\153\165 utf8'
   R.test_utf8_const_in(utf8_const)
end

function gireg.utf8_out()
   local R = lgi.Regress
   local utf8_nonconst = 'nonconst \226\153\165 utf8'
   check(R.test_utf8_out() == utf8_nonconst)
end

function gireg.utf8_inout()
   local R = lgi.Regress
   local utf8_const = 'const \226\153\165 utf8'
   local utf8_nonconst = 'nonconst \226\153\165 utf8'
   check(R.test_utf8_inout(utf8_const) == utf8_nonconst)
end

function gireg.filename_return()
   local R = lgi.Regress
   local fns = R.test_filename_return()
   check(type(fns) == 'table')
   check(#fns == 2)
   check(fns[1] == 'åäö')
   check(fns[2] == '/etc/fstab')
end

function gireg.utf8_int_out_utf8()
   local R = lgi.Regress
   check(R.test_int_out_utf8('') == 0)
   check(R.test_int_out_utf8('abc') == 3)
   local utf8_const = 'const \226\153\165 utf8'
   check(R.test_int_out_utf8(utf8_const) == 12)
end

function gireg.multi_double_args()
   local R = lgi.Regress
   local o1, o2 = R.test_multi_double_args(1)
   check(o1 == 2 and o2 == 3)
   check(#{R.test_multi_double_args(1)} == 2)
end

function gireg.utf8_out_out()
   local R = lgi.Regress
   local o1, o2 = R.test_utf8_out_out()
   check(o1 == 'first' and o2 == 'second')
   check(#{R.test_utf8_out_out()} == 2)
end

function gireg.utf8_out_nonconst_return()
   local R = lgi.Regress
   local o1, o2 = R.test_utf8_out_nonconst_return()
   check(o1 == 'first' and o2 == 'second')
   check(#{R.test_utf8_out_nonconst_return()} == 2)
end

function gireg.utf8_null_in()
   local R = lgi.Regress
   R.test_utf8_null_in(nil)
   R.test_utf8_null_in()
end

function gireg.utf8_null_out()
   local R = lgi.Regress
   check(R.test_utf8_null_out() == nil)
end

function gireg.array_int_in()
   local R = lgi.Regress
   check(R.test_array_int_in{1,2,3} == 6)
   check(R.test_array_int_in{1.1,2,3} == 6)
   check(R.test_array_int_in{} == 0)
   check(not pcall(R.test_array_int_in, nil))
   check(not pcall(R.test_array_int_in, 'help'))
   check(not pcall(R.test_array_int_in, {'help'}))
end

function gireg.array_int_out()
   local R = lgi.Regress
   local a = R.test_array_int_out()
   check(#a == 5)
   check(a[1] == 0 and a[2] == 1 and a[3] == 2 and a[4] == 3 and a[5] == 4)
   check(#{R.test_array_int_out()} == 1)
end

function gireg.array_int_inout()
   local R = lgi.Regress
   local a = R.test_array_int_inout({1, 2, 3, 4, 5})
   check(#a == 4)
   check(a[1] == 3 and a[2] == 4 and a[3] == 5 and a[4] == 6)
   check(#{R.test_array_int_inout({1, 2, 3, 4, 5})} == 1)
   check(not pcall(R.test_array_int_inout, nil))
   check(not pcall(R.test_array_int_inout, 'help'))
   check(not pcall(R.test_array_int_inout, {'help'}))
end

function gireg.array_gint8_in()
   local R = lgi.Regress
   check(R.test_array_gint8_in{1,2,3} == 6)
   check(R.test_array_gint8_in{1.1,2,3} == 6)
   check(R.test_array_gint8_in('0123') == 48 + 49 + 50 + 51)
   check(R.test_array_gint8_in(bytes.new('0123')) == 48 + 49 + 50 + 51)
   check(R.test_array_gint8_in{} == 0)
   check(not pcall(R.test_array_gint8_in, nil))
   check(not pcall(R.test_array_gint8_in, {'help'}))
end

function gireg.array_gint16_in()
   local R = lgi.Regress
   check(R.test_array_gint16_in{1,2,3} == 6)
   check(R.test_array_gint16_in{1.1,2,3} == 6)
   check(R.test_array_gint16_in{} == 0)
   check(not pcall(R.test_array_gint16_in, nil))
   check(not pcall(R.test_array_gint16_in, 'help'))
   check(not pcall(R.test_array_gint16_in, {'help'}))
end

function gireg.array_gint32_in()
   local R = lgi.Regress
   check(R.test_array_gint32_in{1,2,3} == 6)
   check(R.test_array_gint32_in{1.1,2,3} == 6)
   check(R.test_array_gint32_in{} == 0)
   check(not pcall(R.test_array_gint32_in, nil))
   check(not pcall(R.test_array_gint32_in, 'help'))
   check(not pcall(R.test_array_gint32_in, {'help'}))
end

function gireg.array_gint64_in()
   local R = lgi.Regress
   check(R.test_array_gint64_in{1,2,3} == 6)
   check(R.test_array_gint64_in{1.1,2,3} == 6)
   check(R.test_array_gint64_in{} == 0)
   check(not pcall(R.test_array_gint64_in, nil))
   check(not pcall(R.test_array_gint64_in, 'help'))
   check(not pcall(R.test_array_gint64_in, {'help'}))
end

function gireg.array_strv_in()
   local R = lgi.Regress
   check(R.test_strv_in{'1', '2', '3'})
   check(not pcall(R.test_strv_in))
   check(not pcall(R.test_strv_in, '1'))
   check(not pcall(R.test_strv_in, 1))
   check(not R.test_strv_in{'3', '2', '1'})
   check(not R.test_strv_in{'1', '2', '3', '4'})
end

function gireg.array_gtype_in()
   local R = lgi.Regress
   local str = R.test_array_gtype_in {
      lgi.GObject.Value._gtype,
      lgi.GObject.type_from_name('gchar')
   }
   check(str == '[GValue,gchar,]')
   check(R.test_array_gtype_in({}) == '[]')
   check(not pcall(R.test_array_gtype_in))
   check(not pcall(R.test_array_gtype_in, ''))
   check(not pcall(R.test_array_gtype_in, 1))
   check(not pcall(R.test_array_gtype_in, function() end))
end

function gireg.array_strv_out()
   local R = lgi.Regress
   local a = R.test_strv_out()
   check(type(a) == 'table' and #a == 5)
   check(table.concat(a, ' ') == 'thanks for all the fish')
   check(#{R.test_strv_out()} == 1)
end

function gireg.array_strv_out_container()
   local R = lgi.Regress
   local a = R.test_strv_out_container()
   check(type(a) == 'table' and #a == 3)
   check(table.concat(a, ' ') == '1 2 3')
end

function gireg.array_strv_outarg()
   local R = lgi.Regress
   local a = R.test_strv_outarg()
   check(type(a) == 'table' and #a == 3)
   check(table.concat(a, ' ') == '1 2 3')
   check(#{R.test_strv_outarg()} == 1)
end

function gireg.array_fixed_size_int_out()
   local R = lgi.Regress
   local a = R.test_array_fixed_size_int_out()
   check(type(a) == 'table' and #a == 5)
   check(a[1] == 0 and a[2] == 1 and a[3] == 2 and a[4] == 3 and a[5] == 4)
   check(#{R.test_array_fixed_size_int_out()} == 1)
end

function gireg.array_fixed_size_int_return()
   local R = lgi.Regress
   local a = R.test_array_fixed_size_int_return()
   check(type(a) == 'table' and #a == 5)
   check(a[1] == 0 and a[2] == 1 and a[3] == 2 and a[4] == 3 and a[5] == 4)
   check(#{R.test_array_fixed_size_int_return()} == 1)
end

function gireg.array_strv_out_c()
   local R = lgi.Regress
   local a = R.test_strv_out_c()
   check(type(a) == 'table' and #a == 5)
   check(table.concat(a, ' ') == 'thanks for all the fish')
end

function gireg.array_int_full_out()
   local R = lgi.Regress
   local a = R.test_array_int_full_out()
   check(type(a) == 'table' and #a == 5)
   check(a[1] == 0 and a[2] == 1 and a[3] == 2 and a[4] == 3 and a[5] == 4)
   check(#{R.test_array_int_full_out()} == 1)
end

function gireg.array_int_full_out()
   local R = lgi.Regress
   local a = R.test_array_int_full_out()
   check(type(a) == 'table' and #a == 5)
   check(a[1] == 0 and a[2] == 1 and a[3] == 2 and a[4] == 3 and a[5] == 4)
   check(#{R.test_array_int_full_out()} == 1)
end

function gireg.array_int_null_in()
   local R = lgi.Regress
   R.test_array_int_null_in()
   R.test_array_int_null_in(nil)
end

function gireg.array_int_null_out()
   local R = lgi.Regress
   local a = R.test_array_int_null_out()
   check(type(a) == 'table' and not next(a))
end

function gireg.glist_nothing_return()
   local R = lgi.Regress
   check(select('#', R.test_glist_nothing_return()) == 1)
   a = R.test_glist_nothing_return()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.glist_nothing_return2()
   local R = lgi.Regress
   check(select('#', R.test_glist_nothing_return2()) == 1)
   a = R.test_glist_nothing_return2()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.glist_container_return()
   local R = lgi.Regress
   check(select('#', R.test_glist_container_return()) == 1)
   a = R.test_glist_container_return()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.glist_everything_return()
   local R = lgi.Regress
   check(select('#', R.test_glist_everything_return()) == 1)
   a = R.test_glist_everything_return()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.glist_nothing_in()
   local R = lgi.Regress
   R.test_glist_nothing_in  {'1', '2', '3'}
end

function gireg.glist_nothing_in2()
   local R = lgi.Regress
   R.test_glist_nothing_in2  {'1', '2', '3'}
end

function gireg.glist_null_in()
   local R = lgi.Regress
   R.test_glist_null_in {}
   R.test_glist_null_in(nil)
   R.test_glist_null_in()
end

function gireg.glist_null_out()
   local R = lgi.Regress
   check(select('#', R.test_glist_null_out()) == 1)
   local a = R.test_glist_null_out()
   check(type(a) == 'table' and #a == 0)
end

function gireg.gslist_nothing_return()
   local R = lgi.Regress
   check(select('#', R.test_gslist_nothing_return()) == 1)
   a = R.test_gslist_nothing_return()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.gslist_nothing_return2()
   local R = lgi.Regress
   check(select('#', R.test_gslist_nothing_return2()) == 1)
   a = R.test_gslist_nothing_return2()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.gslist_container_return()
   local R = lgi.Regress
   check(select('#', R.test_gslist_container_return()) == 1)
   a = R.test_gslist_container_return()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.gslist_everything_return()
   local R = lgi.Regress
   check(select('#', R.test_gslist_everything_return()) == 1)
   a = R.test_gslist_everything_return()
   check(type(a) == 'table' and #a == 3)
   check(a[1] == '1' and a[2] == '2' and a[3] == '3')
end

function gireg.gslist_nothing_in()
   local R = lgi.Regress
   R.test_gslist_nothing_in  {'1', '2', '3'}
end

function gireg.gslist_nothing_in2()
   local R = lgi.Regress
   R.test_gslist_nothing_in2  {'1', '2', '3'}
end

function gireg.gslist_null_in()
   local R = lgi.Regress
   R.test_gslist_null_in {}
   R.test_gslist_null_in(nil)
   R.test_gslist_null_in()
end

function gireg.gslist_null_out()
   local R = lgi.Regress
   check(select('#', R.test_gslist_null_out()) == 1)
   local a = R.test_gslist_null_out()
   check(type(a) == 'table' and #a == 0)
end

function gireg.ghash_null_return()
   local R = lgi.Regress
   check(select('#', R.test_ghash_null_return()) == 1)
   check(R.test_ghash_null_return() == nil)
end

local function size_htab(h)
   local size = 0
   for _ in pairs(h) do size = size + 1 end
   return size
end

function gireg.ghash_nothing_return()
   local R = lgi.Regress
   local count = 0
   check(select('#', R.test_ghash_nothing_return()) == 1)
   local h = R.test_ghash_nothing_return()
   check(type(h) == 'table')
   check(size_htab(h) == 3)
   check(h.foo == 'bar' and h.baz == 'bat' and h.qux == 'quux')
end

function gireg.ghash_container_return()
   local R = lgi.Regress
   local count = 0
   check(select('#', R.test_ghash_container_return()) == 1)
   local h = R.test_ghash_container_return()
   check(type(h) == 'table')
   check(size_htab(h) == 3)
   check(h.foo == 'bar' and h.baz == 'bat' and h.qux == 'quux')
end

function gireg.ghash_everything_return()
   local R = lgi.Regress
   local count = 0
   check(select('#', R.test_ghash_everything_return()) == 1)
   local h = R.test_ghash_everything_return()
   check(type(h) == 'table')
   check(size_htab(h) == 3)
   check(h.foo == 'bar' and h.baz == 'bat' and h.qux == 'quux')
end

function gireg.ghash_null_in()
   local R = lgi.Regress
   R.test_ghash_null_in(nil)
   R.test_ghash_null_in()
   check(not pcall(R.test_ghash_null_in,1))
   check(not pcall(R.test_ghash_null_in,'string'))
   check(not pcall(R.test_ghash_null_in,function() end))
end

function gireg.ghash_null_out()
   local R = lgi.Regress
   check(R.test_ghash_null_out() == nil)
end

function gireg.ghash_nothing_in()
   local R = lgi.Regress
   R.test_ghash_nothing_in({ foo = 'bar', baz = 'bat', qux = 'quux' })
   check(not pcall(R.test_ghash_nothing_in))
   check(not pcall(R.test_ghash_nothing_in, 1))
   check(not pcall(R.test_ghash_nothing_in, 'test'))
   check(not pcall(R.test_ghash_nothing_in, function() end))
end

function gireg.ghash_nested_everything_return()
   local R = lgi.Regress
   check(select('#', R.test_ghash_nested_everything_return) == 1);
   local a = R.test_ghash_nested_everything_return()
   check(type(a) == 'table')
   check(size_htab(a) == 1)
   check(type(a.wibble) == 'table')
   check(size_htab(a.wibble) == 3)
   check(a.wibble.foo == 'bar' and a.wibble.baz == 'bat'
	 and a.wibble.qux == 'quux')
end

function gireg.enum()
   local R = lgi.Regress
   check(R.TestEnum.VALUE1 == 0)
   check(R.TestEnum.VALUE2 == 1)
   check(R.TestEnum.VALUE3 == -1)
   check(R.TestEnum[0] == 'VALUE1')
   check(R.TestEnum[1] == 'VALUE2')
   check(R.TestEnum[-1] == 'VALUE3')
   check(R.TestEnum[43] == nil)
   check(R.test_enum_param(0) == 'value1')
   check(R.test_enum_param(1) == 'value2')
   check(R.test_enum_param(-1) == 'value3')

   check(R.TestEnumUnsigned.VALUE1 == 1)
   check(R.TestEnumUnsigned.VALUE2 == 0x80000000)
   check(R.TestEnumUnsigned[1] == 'VALUE1')
   check(R.TestEnumUnsigned[0x80000000] == 'VALUE2')
   check(R.TestEnumUnsigned[-1] == nil)
end

function gireg.flags()
   local R = lgi.Regress
   check(R.TestFlags.FLAG1 == 1)
   check(R.TestFlags.FLAG2 == 2)
   check(R.TestFlags.FLAG3 == 4)
   check(R.TestFlags[7].FLAG1 == 1)
   check(R.TestFlags[7].FLAG2 == 2)
   check(R.TestFlags[7].FLAG3 == 4)
   check(R.TestFlags[3].FLAG1 == 1)
   check(R.TestFlags[3].FLAG2 == 2)
   check(R.TestFlags[3].FLAG3 == nil)
end

function gireg.const()
   local R = lgi.Regress
   checkv(R.INT_CONSTANT, 4422, 'number')
   checkv(R.DOUBLE_CONSTANT, 44.22, 'number')
   checkv(R.STRING_CONSTANT, 'Some String', 'string')
   checkv(R.Mixed_Case_Constant, 4423, 'number')
end

function gireg.struct_a()
   local R = lgi.Regress
   check(select('#', R.TestStructA()) == 1)
   local a = R.TestStructA()
   check(type(a) == 'userdata')
   a.some_int = 42
   check(a.some_int == 42)
   a.some_int8 = 12
   check(a.some_int8 == 12)
   a.some_double = 3.14
   check(a.some_double == 3.14)
   a.some_enum = R.TestEnum.VALUE2
   check(a.some_enum == R.TestEnum.VALUE2)
   a = R.TestStructA { some_int = 42, some_int8 = 12,
		       some_double = 3.14, some_enum = R.TestEnum.VALUE2 }
   a.some_int = 43
   a.some_int8 = 13
   check(a.some_int == 43)
   check(a.some_int8 == 13)
   check(a.some_double == 3.14)
   check(a.some_enum == R.TestEnum.VALUE2)
   a.some_double = 3.15
   check(a.some_int == 43)
   check(a.some_int8 == 13)
   check(a.some_double == 3.15)
   check(a.some_enum == R.TestEnum.VALUE2)
   a.some_enum = R.TestEnum.VALUE3
   check(a.some_int == 43)
   check(a.some_int8 == 13)
   check(a.some_double == 3.15)
   check(a.some_enum == R.TestEnum.VALUE3)
   check(not pcall(function() return a.foo end))
   check(not pcall(function() a.foo = 1 end))
   check(select('#', (function() a.some_int = 0 end)()) == 0)
   check(select('#', (function() return a.some_int end)()) == 1)
   check(select('#', (function() local b = a.some_int end)()) == 0)
end

function gireg.struct_a_clone()
   local R = lgi.Regress
   local a = R.TestStructA { some_int = 42, some_int8 = 12, some_double = 3.14,
			     some_enum = R.TestEnum.VALUE2 }
   check(a == a)
   check(select('#', a:clone()) == 1)
   local b = a:clone()
   check(type(b) == 'userdata')
   check(b ~= a)
   check(b == b)
   check(b.some_int == 42)
   check(b.some_int8 == 12)
   check(b.some_double == 3.14)
   check(b.some_enum == R.TestEnum.VALUE2)
   check(a.some_int == 42)
   check(a.some_int8 == 12)
   check(a.some_double == 3.14)
   check(a.some_enum == R.TestEnum.VALUE2)
end

function gireg.struct_b()
   local R = lgi.Regress
   local b = R.TestStructB()

   -- Basic fields assignments.
   b.some_int8 = 13
   check(b.some_int8 == 13)
   b.nested_a.some_int = -1
   check(b.some_int8 == 13)
   check(b.nested_a.some_int == -1)
   b.nested_a.some_int8 = -2
   check(b.some_int8 == 13)
   check(b.nested_a.some_int == -1)
   check(b.nested_a.some_int8 == -2)

   -- Whole nested structure assignment.
   b.nested_a = { some_int = 42, some_int8 = 12,
		  some_double = 3.14, some_enum = R.TestEnum.VALUE2 }
   check(b.nested_a.some_int == 42)
   check(b.nested_a.some_int8 == 12)
   check(b.nested_a.some_double == 3.14)
   check(b.nested_a.some_enum == R.TestEnum.VALUE2)

   -- Nested structure construction.
   b = R.TestStructB { some_int8 = 21, nested_a =
		       { some_int = 42, some_int8 = 12,
			 some_double = 3.14, some_enum = R.TestEnum.VALUE2 } }
   check(b.some_int8 == 21)
   check(b.nested_a.some_int == 42)
   check(b.nested_a.some_int8 == 12)
   check(b.nested_a.some_double == 3.14)
   check(b.nested_a.some_enum == R.TestEnum.VALUE2)
end

function gireg.struct_b_clone()
   local R = lgi.Regress
   local b = R.TestStructB { some_int8 = 21, nested_a =
			     { some_int = 42, some_int8 = 12,
			       some_double = 3.14,
			       some_enum = R.TestEnum.VALUE2 } }
   check(b == b)
   check(select('#', b:clone()) == 1)
   local bc = b:clone()
   check(type(bc) == 'userdata')
   check(bc ~= b)
   check(bc == bc)
   check(bc.some_int8 == 21)
   check(bc.nested_a.some_int == 42)
   check(bc.nested_a.some_int8 == 12)
   check(bc.nested_a.some_double == 3.14)
   check(bc.nested_a.some_enum == R.TestEnum.VALUE2)
   check(bc.nested_a.some_int == 42)
   check(bc.nested_a.some_int8 == 12)
   check(bc.nested_a.some_double == 3.14)
   check(bc.nested_a.some_enum == R.TestEnum.VALUE2)

   check(b.some_int8 == 21)
   check(b.nested_a.some_int == 42)
   check(b.nested_a.some_int8 == 12)
   check(b.nested_a.some_double == 3.14)
   check(b.nested_a.some_enum == R.TestEnum.VALUE2)
   check(b.nested_a.some_int == 42)
   check(b.nested_a.some_int8 == 12)
   check(b.nested_a.some_double == 3.14)
   check(b.nested_a.some_enum == R.TestEnum.VALUE2)
end

function gireg.boxed_a_equals()
   local R = lgi.Regress
   check(R.TestSimpleBoxedA({ some_int = 1, some_int8 = 2,
			      some_double = 3.14 }):equals(
	    R.TestSimpleBoxedA({ some_int = 1, some_int8 = 2,
				 some_double = 3.14 })))
   check(not R.TestSimpleBoxedA({ some_int = 2, some_int8 = 2,
				  some_double = 3.14 }):equals(
	    R.TestSimpleBoxedA({ some_int = 1, some_int8 = 2,
				 some_double = 3.14 })))
   check(R.TestSimpleBoxedA():equals(R.TestSimpleBoxedA()))
   check(not pcall(R.TestSimpleBoxedA().equals))
   check(not pcall(R.TestSimpleBoxedA().equals, nil))
   check(not pcall(R.TestSimpleBoxedA().equals, {}))
   check(not pcall(R.TestSimpleBoxedA().equals, 1))
   check(not pcall(R.TestSimpleBoxedA().equals, 'string'))
   check(not pcall(R.TestSimpleBoxedA().equals, function() end))
end

function gireg.boxed_a_const_return()
   local R = lgi.Regress
   check(select('#', R.test_simple_boxed_a_const_return()) == 1)
   local a = R.test_simple_boxed_a_const_return()
   check(a.some_int == 5)
   check(a.some_int8 == 6)
   check(a.some_double == 7)
end

function gireg.boxed_new()
   local R = lgi.Regress
   check(select('#', R.TestBoxed.new()) == 1)
   local bn = R.TestBoxed.new()
   local bac1 = R.TestBoxed.new_alternative_constructor1(1)
   check(bac1.some_int8 == 1)
   local bac2 = R.TestBoxed.new_alternative_constructor2(1, 2)
   check(bac2.some_int8 == 3)
   local bac3 = R.TestBoxed.new_alternative_constructor3('25')
   check(bac3.some_int8 == 25)
end

function gireg.boxed_copy()
   local R = lgi.Regress
   local b = R.TestBoxed.new()
   b.some_int8 = 1
   b.nested_a = { some_int = 1, some_int8 = 2, some_double = 3.14 }
   check(select('#', b:copy()) == 1)
   local bc = b:copy()
   check(bc ~= b)
   check(bc.some_int8 == 1)
   check(bc.nested_a.some_int == 1)
   check(bc.nested_a.some_int8 == 2)
   check(bc.nested_a.some_double == 3.14)
end

function gireg.boxed_equals()
   local R = lgi.Regress
   local b1 = R.TestBoxed.new()
   b1.some_int8 = 1
   b1.nested_a = { some_int = 1, some_int8 = 2, some_double = 3.14 }
   local b2 = R.TestBoxed.new()
   b2.some_int8 = 1
   b2.nested_a = { some_int = 1, some_int8 = 2, some_double = 3.14 }
   check(b1:equals(b2))
   b1.some_int8 = 2
   check(not b1:equals(b2))
   b1.some_int8 = 1
   b1.nested_a.some_int = 2
   check(not b1:equals(b2))
   b1.nested_a.some_int = 1
   check(b1:equals(b2))
end

function gireg.closure_simple()
   local R = lgi.Regress
   local closure = GObject.Closure(function(...)
				      check(select('#', ...) == 0)
				      return 42
				end)
   checkv(R.test_closure(closure, 42), 42, 'number')
   local res = GObject.Value('gint')
   closure:invoke(res, {}, nil)
   check(res.gtype == 'gint' and res.value == 42)
end

function gireg.closure_arg()
   local R = lgi.Regress
   local closure = GObject.Closure(function(int, ...)
				      check(select('#', ...) == 0)
				      return int
				end)
   checkv(R.test_closure_one_arg(closure, 43), 43, 'number')
   local res = GObject.Value('gint')
   closure:invoke(res, { GObject.Value('gint', 43) }, nil)
   check(res.gtype == 'gint' and res.value == 43)
end

function gireg.gvalue_assign()
   local V = GObject.Value

   local v = V()
   check(v.gtype == nil)
   check(v.value == nil)
   v.gtype = 'gchararray'
   check(v.gtype == 'gchararray')
   check(v.value == nil)
   v.value = 'label'
   check(v.value == 'label')
   v.value = nil
   check(v.value == nil)
   check(v.gtype == 'gchararray')
   v.value = 'label'
   v.gtype = nil
   check(v.gtype == nil)
   check(v.value == nil)

   v.gtype = 'gint'
   v.value = 1
   check(v.gtype == 'gint')
   check(v.value == 1)
   v.gtype = 'gdouble'
   check(v.gtype == 'gdouble')
   check(v.value == 1)
   v.value = 3.14
   v.gtype = 'gint'
   check(v.gtype == 'gint')
   check(v.value == 3)
end

function gireg.gvalue_arg()
   local R = lgi.Regress
   checkv(R.test_int_value_arg(GObject.Value('gint', 42)), 42, 'number')
end

function gireg.gvalue_return()
   local R = lgi.Regress
   local v = R.test_value_return(43)
   checkv(v.value, 43, 'number')
   check(v.gtype == 'gint', 'incorrect value type')
end

function gireg.gvalue_date()
   local R = lgi.Regress
   local v = R.test_date_in_gvalue()
   check(v.gtype == 'GDate')
   check(v.value:get_day() == 5)
   check(v.value:get_month() == 12)
   check(v.value:get_year() == 1984)
   local d = GLib.Date()
   d:set_dmy(25, 1, 1975)
   v = GObject.Value(GLib.Date, d)
   check(v.gtype == 'GDate')
   check(v.value:get_day() == 25)
   check(v.value:get_month() == 1)
   check(v.value:get_year() == 1975)
end

function gireg.gvalue_strv()
   local R = lgi.Regress
   local v = R.test_strv_in_gvalue()
   check(v.gtype == 'GStrv')
   check(#v.value == 3)
   check(v.value[1] == 'one')
   check(v.value[2] == 'two')
   check(v.value[3] == 'three')
   v = GObject.Value('GStrv', { '1', '2', '3' })
   check(#v.value == 3)
   check(v.value[1] == '1')
   check(v.value[2] == '2')
   check(v.value[3] == '3')
end

function gireg.obj_create()
   local R = lgi.Regress
   local o = R.TestObj()
   check(o)
   check(type(o) == 'userdata')
   check(select('#', R.TestObj()) == 1)
   o = R.TestObj.new_from_file('unused')
   check(type(o) == 'userdata')
   check(select('#', R.TestObj.new_from_file('unused')) == 1)
end

function gireg.obj_methods()
   local R = lgi.Regress
   if R.TestObj._method.do_matrix then
      R.TestObj._method.invoke_matrix = R.TestObj._method.do_matrix
      R.TestObj._method.do_matrix = nil
   end
   local o = R.TestObj()
   check(o:instance_method() == -1)
   check(o.static_method(42) == 42)
   local y, z, q = o:torture_signature_0(1, 'foo', 2)
   check(y == 1)
   check(z == 2)
   check(q == 5)
   local y, z, q = o:torture_signature_1(1, 'foo', 2)
   check(y == 1)
   check(z == 2)
   check(q == 5)
   local res, msg, code = o:torture_signature_1(1, 'foo', 3)
   check(not res)
   check(type(msg) == 'string')
   check(type(code) == 'number')
   check(o:invoke_matrix('unused') == 42)
end

function gireg.obj_null_args()
   local R = lgi.Regress
   R.func_obj_null_in(nil)
   R.func_obj_null_in()
   check(R.TestObj.null_out() == nil)
   check(select('#', R.TestObj.null_out()) == 1)
end

function gireg.obj_virtual_methods()
   local R = lgi.Regress
   local o = R.TestObj()
   check(o:virtual_matrix('unused') == 42)
end

function gireg.obj_prop_int()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.int == 0)
   o.int = 42
   check(o.int == 42)
   check(not pcall(function() o.int = {} end))
   check(not pcall(function() o.int = 'lgi' end))
   check(not pcall(function() o.int = nil end))
   check(not pcall(function() o.int = function() end end))
end

function gireg.obj_prop_float()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.float == 0)
   o.float = 42.1
   checkvf(o.float, 42.1, 0.00001)
   check(not pcall(function() o.float = {} end))
   check(not pcall(function() o.float = 'lgi' end))
   check(not pcall(function() o.float = nil end))
   check(not pcall(function() o.float = function() end end))
end

function gireg.obj_prop_double()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.double == 0)
   o.double = 42.1
   checkvf(o.double, 42.1, 0.0000000001)
   check(not pcall(function() o.double = {} end))
   check(not pcall(function() o.double = 'lgi' end))
   check(not pcall(function() o.double = nil end))
   check(not pcall(function() o.double = function() end end))
end

function gireg.obj_prop_string()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.string == nil)
   o.string = 'lgi'
   check(o.string == 'lgi')
   o.string = nil
   check(o.string == nil)
   check(not pcall(function() o.string = {} end))
   check(not pcall(function() o.string = function() end end))
end

function gireg.obj_prop_bare()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.bare == nil)
   local pv = R.TestObj()
   o.bare = pv
   check(o.bare == pv)
   o.bare = nil
   check(o.bare == nil)
   o:set_bare(pv)
   check(o.bare == pv)
   o.bare = nil
   check(o.bare == nil)
   check(not pcall(function() o.bare = {} end))
   check(not pcall(function() o.bare = 42 end))
   check(not pcall(function() o.bare = 'lgi' end))
   check(not pcall(function() o.bare = function() end end))
   check(not pcall(function() o.bare = R.TestBoxed() end))
end

function gireg.obj_prop_boxed()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.boxed == nil)
   local pv = R.TestBoxed()
   o.boxed = pv
   check(o.boxed:equals(pv))
   o.boxed = nil
   check(o.boxed == nil)
   check(not pcall(function() o.boxed = {} end))
   check(not pcall(function() o.boxed = 42 end))
   check(not pcall(function() o.boxed = 'lgi' end))
   check(not pcall(function() o.boxed = function() end end))
   check(not pcall(function() o.boxed = R.TestObj() end))
end

function gireg.obj_prop_hash()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.hash_table == nil)
   o.hash_table = { a = 1, b = 2 }
   local ov = o.hash_table
   check(ov.a == 1 and ov.b == 2)
   check(not pcall(function() o.hash_table = 42 end))
   check(not pcall(function() o.hash_table = 'lgi' end))
   check(not pcall(function() o.hash_table = function() end end))
   check(not pcall(function() o.hash_table = R.TestObj() end))
   check(not pcall(function() o.hash_table = R.TestBoxed() end))
end

function gireg.obj_prop_list()
   local R = lgi.Regress
   local o = R.TestObj()

   check(o.hash_table == nil)
   o.list = { 'one', 'two', 'three',  }
   local ov = o.list
   check(#ov == 3 and ov[1] == 'one' and ov[2] == 'two' and ov[3] == 'three')
   check(not pcall(function() o.list = 42 end))
   check(not pcall(function() o.list = 'lgi' end))
   check(not pcall(function() o.list = function() end end))
   check(not pcall(function() o.list = R.TestObj() end))
   check(not pcall(function() o.list = R.TestBoxed() end))
end

function gireg.obj_prop_dynamic()
   local R = lgi.Regress
   local o = R.TestObj()

   -- Remove static property information, force lgi to use dynamic
   -- GLib property system.
   local old_prop = R.TestObj.int
   R.TestObj._property.int = nil
   check(R.TestObj.int == nil)

   check(o.int == 0)
   o.int = 3
   check(o.int == 3)
   check(not pcall(function() o.int = 'string' end))
   check(not pcall(function() o.int = {} end))
   check(not pcall(function() o.int = true end))
   check(not pcall(function() o.int = function() end end))

   -- Restore TestObj to work normally.
   R.TestObj._property.int = old_prop
end

function gireg.obj_subobj()
   local R = lgi.Regress
   local o = R.TestSubObj()
   local pv = R.TestObj()
   check(o:instance_method() == 0)
   o.bare = pv
   check(o.bare == pv)
   o:unset_bare()
   check(o.bare == nil)
   o = R.TestSubObj.new()
   o:set_bare(pv)
   check(o.bare == pv)
   o:unset_bare()
   check(o.bare == nil)
end

function gireg.obj_naming()
   local R = lgi.Regress
   local o = R.TestWi8021x()
   o:set_testbool(true)
   check(o.testbool == true)
   o.testbool = false
   check(o:get_testbool() == false)
end

function gireg.obj_floating()
   local R = lgi.Regress
   local o = R.TestFloating()
   check(o)
   o = nil
   collectgarbage()
   collectgarbage()
end

function gireg.obj_fundamental()
   local R = lgi.Regress
   local f = R.TestFundamentalSubObject.new('foo-nda-mental')
   check(f)
   check(f.data == 'foo-nda-mental')
   local v = lgi.GObject.Value(R.TestFundamentalSubObject, f)
   check(v.value == f)
   f = nil
   collectgarbage()
end

function gireg.callback_simple()
   local R = lgi.Regress
   check(R.test_callback(function() return 42 end) == 42)
   check(R.test_callback() == 0)
   check(R.test_callback(nil) == 0)
   check(not pcall(R.test_callback, 1))
   check(not pcall(R.test_callback, 'foo'))
   check(not pcall(R.test_callback, {}))
   check(not pcall(R.test_callback, R))

   check(R.test_multi_callback(function() return 22 end) == 44)
   check(R.test_multi_callback() == 0)
end

function gireg.callback_data()
   local R = lgi.Regress
   local called
   R.test_simple_callback(function() called = true end)
   check(called)
   check(R.test_callback_user_data(function() return 42 end) == 42)

   called = nil
   R.TestObj.static_method_callback(function() called = true return 42 end)
   check(called)
   local o = R.TestObj()
   called = nil
   o.static_method_callback(function() called = true return 42 end)
   check(called)
   called = nil
   o:instance_method_callback(function() called = true return 42 end)
   check(called)
end

function gireg.callback_notified()
   local R = lgi.Regress
   check(R.test_callback_destroy_notify(function() return 1 end) == 1)
   check(R.test_callback_destroy_notify(function() return 2 end) == 2)
   check(R.test_callback_destroy_notify(function() return 3 end) == 3)
   collectgarbage()
   collectgarbage()
   check(R.test_callback_thaw_notifications() == 6)

   R.TestObj.new_callback(function() return 1 end)
   collectgarbage()
   collectgarbage()
   check(R.test_callback_thaw_notifications() == 1)
end

function gireg.callback_async()
   local R = lgi.Regress
   R.test_callback_async(function() return 1 end)
   collectgarbage()
   collectgarbage()
   check(R.test_callback_thaw_async() == 1)
end

-- Basic GObject testing
local gobject = testgroup.new('gobject')

function gobject.object_new()
   local GObject = lgi.GObject
   local o = GObject.Object()
   o = nil
   collectgarbage()
   collectgarbage()
end

function gobject.initunk_new()
   local GObject = lgi.GObject
   local o = GObject.InitiallyUnowned()

   -- Simulate sink by external container
   o:ref_sink()
   o:unref()

   o = nil
   collectgarbage()
   collectgarbage()
end

-- Variant testing
local variant = testgroup.new('variant')

function variant.gvalue()
   local var1, var2 = GLib.Variant.new_string('foo'),
   GLib.Variant.new_string('bar')
   local val = GObject.Value(GObject.Type.VARIANT, var1)
   check(val.gtype == GObject.Type.VARIANT)
   check(val.value == var1)
   val.value = var2
   check(val.value == var2)
   val.value = nil
   check(val.value == nil)
   check(val.gtype == GObject.Type.VARIANT)
end

function variant.newv_basic()
   local V, v = GLib.Variant
   v = V.new('b', true)
   check(v.type == 'b' and v:get_boolean() == true)
   v = V.new('y', 32)
   check(v.type == 'y' and v:get_byte() == 32)
   v = V.new('n', 13)
   check(v.type == 'n' and v:get_int16() == 13)
   v = V.new('q', 38)
   check(v.type == 'q' and v:get_uint16() == 38)
   v = V.new('i', 32)
   check(v.type == 'i' and v:get_int32() == 32)
   v = V.new('u', 35)
   check(v.type == 'u' and v:get_uint32() == 35)
   v = V.new('x', 39)
   check(v.type == 'x' and v:get_int64() == 39)
   v = V.new('t', 987)
   check(v.type == 't' and v:get_uint64() == 987)
   v = V.new('d', 3.1415927)
   check(v.type == 'd' and v:get_double() == 3.1415927)
   v = V.new('s', 'Hello')
   check(v.type == 's' and v:get_string() == 'Hello')
   v = V.new('o', '/object/path')
   check(v.type == 'o' and v:get_string() == '/object/path')
   v = V.new('g', "asi")
   check(v.type == 'g' and v:get_string() == 'asi')
   local vv = V.new('s', 'inner')
   v = V.new('v', vv)
   check(v.type == 'v' and v:get_variant() == vv)
   v = V.new('ay', 'bytestring')
   check(v.type == 'ay' and tostring(v:get_bytestring()) == 'bytestring')
end

function variant.newv_variant()
   local V, v, vv = GLib.Variant
   vv = V('i', 14)
   v = V('v', vv)
   check(v.type == 'v' and v:n_children() == 1 and v:get_child_value(0) == vv)
end

function variant.newv_maybe()
   local V, v = GLib.Variant
   v = V('mi', 42)
   check(v.type == 'mi' and v:n_children() == 1
	 and v:get_child_value(0).type == 'i'
	 and v:get_child_value(0):get_int32() == 42)
   v = V('mi')
   check(v.type == 'mi' and v:n_children() == 0)
end

function variant.newv_tuple()
   local V, v = GLib.Variant
   v = V.new('()')
   check(v.type == '()' and v:n_children() == 0)
   v = V.new('(i)', {42})
   check(v.type == '(i)' and v:n_children() == 1
	 and v:get_child_value(0).type == 'i'
	 and v:get_child_value(0):get_int32() == 42)
   v = V.new('(mii)', { nil, 1 })
   check(v.type == '(mii)' and v:n_children() == 2
	 and v:get_child_value(0):n_children() == 0)
end

function variant.newv_dictentry()
   local V, v = GLib.Variant
   v = V('{is}', {42, 'Hello'})
   check(v.type == '{is}' and v:n_children() == 2
	 and v:get_child_value(0).type == 'i'
	 and v:get_child_value(0):get_int32() == 42
	 and v:get_child_value(1).type == 's'
	 and v:get_child_value(1):get_string() == 'Hello')
end

function variant.newv_array()
   local V, v = GLib.Variant
   v = V('as', { 'Hello', 'world' })
   check(v.type == 'as' and v:n_children() == 2
	 and v:get_child_value(0):get_string() == 'Hello'
	 and v:get_child_value(1):get_string() == 'world')
   v = V('as', {})
   check(v:n_children() == 0)
   v = V('ams', { 'Hello', nil, 'world', n = 3 })
   check(v:n_children() == 3)
   check(v:get_child_value(0):n_children() == 1
	 and v:get_child_value(0):get_child_value(0):get_string() == 'Hello')
   check(v:get_child_value(1):n_children() == 0)
   check(v:get_child_value(2):n_children() == 1
	 and v:get_child_value(2):get_child_value(0):get_string() == 'world')
end

function variant.newv_dictionary()
   local V, v, vv = GLib.Variant
   v = V('a{sd}', { PI = 3.14, one = 1 })
   check(v:n_children() == 2)
   vv = v:lookup_value('PI', GLib.VariantType.DOUBLE)
   check(vv.type == 'd' and vv:get_double() == 3.14)
   vv = v:lookup_value('one', GLib.VariantType.DOUBLE)
   check(vv.type == 'd' and vv:get_double() == 1)
end

function variant.newv_badtype()
   local V, v = GLib.Variant
   check(not pcall(V.new, '{vs}'))
   check(not pcall(V.new, '{s}'))
   check(not pcall(V.new, '{}'))
   check(not pcall(V.new, '())'))
   check(not pcall(V.new, 'a'))
   check(not pcall(V.new, 'm'))
   check(not pcall(V.new, '{asi}'))
   check(not pcall(V.new, '{mdd}'))
   check(not pcall(V.new, '{is'))
   check(not pcall(V.new, '{is)'))
   check(not pcall(V.new, 'r'))
   check(not pcall(V.new, '*'))
   check(not pcall(V.new, '?'))
   check(not pcall(V.new, 'ii'))
end

function variant.value_simple()
   local V, v = GLib.Variant
   check(V('b', true).value == true)
   check(V('y', 10).value == 10)
   check(V('n', 11).value == 11)
   check(V('q', 12).value == 12)
   check(V('i', 13).value == 13)
   check(V('u', 14).value == 14)
   check(V('q', 15).value == 15)
   check(V('t', 16).value == 16)
   check(V('s', 'I').value == 'I')
   check(V('o', '/o/p').value == '/o/p')
   check(V('g', '(ii)').value == '(ii)')
   v = V('i', 1)
   check(V('v', v).value == v)
   check(V('ay', 'bytestring').value == 'bytestring')
end

function variant.value_container()
   local V, v = GLib.Variant
   check(V('mi', 1).value == 1)
   check(V('mi', nil).value == nil)
   local r
   r = V('{sd}', {'one', 1}).value
   check(type(r) == 'table' and #r == 2 and r[1] == 'one' and r[2] == 1)
   r = V('(imii)', {2, nil, 1}).value
   check(type(r) == 'table' and r.n == 3 and r[1] == 2 and r[2] == nil
	 and r[3] == 1)
   v = V('as', {})
   check(v.value == v)
end

function variant.value_dictionary()
   local V, v = GLib.Variant
   v = V('a{sd}', { one = 1, two = 2 })
   check(v.value.one == 1)
   check(v.value.two == 2)
   check(v.value.three == nil)
   check(v.value[1] == nil)

   v = V('a{is}', { [1] = 'one', [2] = 'two' })
   check(v.value[1] == 'one')
   check(v.value[2] == 'two')
   check(v.value[3] == nil)
   check(v.value.three == nil)
end

function variant.length()
   local V, v = GLib.Variant
   check(#V('s', 'Hello') == 0)
   check(#V('i', 1) == 0)
   check(#V('v', V('i', 1)) == 1)
   check(#V('mi', nil) == 0)
   check(#V('mi', 1) == 1)
   check(#V('(ii)', {1, 2}) == 2)
   check(#V('{sd}', { 'one', 1 }) == 2)
   check(#V('a{sd}', { one = 1 }) == 1)
   check(#V('ai', {}) == 0)
   check(#V('ami', { 1, nil, 2, n = 3 }) == 3)
end

function variant.indexing()
   local V, v = GLib.Variant
   v = V('mi', 1)
   check(v[1] == 1 and v[2] == nil)
   v = V('{sd}', { 'one', 1 })
   check(v[1] == 'one' and v[2] == 1 and v[3] == nil)
   v = V('a{sd}', { one = 1 })
   check(v[1][1] == 'one' and v[1][2] == 1 and v[2] == nil)
   v = V('(si)', { 'hi', 3 })
   check(v[1] == 'hi' and v[2] == 3 and v[3] == nil)
   check(V('s', 'hello')[1] == nil)
end

function variant.serialize()
   local V, v1, v2 = GLib.Variant
   v1 = V('s', 'Hello')
   v2 = V.new_from_data(v1.type, v1.data)
   check(v1:equal(v2))

   -- Make sure that new_from_data properly keeps underlying data alive.
   v1 = nil collectgarbage()
   local _ = v2:print(true)
end

-- Available groups
local groups = {
   'gireg', gireg = gireg,
   'gobject', gobject=gobject,
   'variant', variant = variant,
}

-- Check for debug mode.
if tests_debug or package.loaded.debugger then
   for _, name in ipairs(groups) do
      groups[name].debug = true
      _G[name] = groups[name]
   end
end

-- Cmdline runner.
local failed = false
arg = arg or {}
if #arg == 0 then

   -- Run everything.
   for _, group in ipairs(groups) do
      groups[group]:run()
      failed = failed or groups[group].results.failed > 0
   end
else
   -- Run just those which pass the mask.
   for _, mask in ipairs(arg) do
      local group, groupmask = mask:match('^(.-):(.+)$')
      if not group or not groups[group] then
	 io.write(("No test group for mask `%s' found.\n"):format(mask))
	 return 2
      end
      groups[group]:run(groupmask)
      failed = failed or groups[group].results.failed > 0
   end
end
return not failed and 0 or 1
