--!optimize 2
local SHRINK_CAP = 4096
local INIT_CAP = 256

type b = {
	_buffer: buffer,
	_Cursor: number,
	_capacity: number,
	_instances: { Instance | boolean },
}
export type Writer = b

local function New(): Writer
	return {
		_buffer = buffer.create(INIT_CAP),
		_Cursor = 0,
		_capacity = INIT_CAP,
		_instances = {},
	}
end

@native
local function Alloc(self: Writer, size: number)
	local target = self._Cursor + size
	if target <= self._capacity then
		return
	end

	local newCapacity = self._capacity
	repeat
		newCapacity *= 2
	until newCapacity >= target

	local newBuffer = buffer.create(newCapacity)
	buffer.copy(newBuffer, 0, self._buffer, 0, self._Cursor)
	self._buffer = newBuffer
	self._capacity = newCapacity
end

local function Reserve(self: Writer, size: number)
	Alloc(self, size)
	local offset = self._Cursor
	self._Cursor += size
	return self._buffer, offset
end

--Dumps the bytes with the exact amout of length
local function Dump(self: Writer)
	-- creates new buffer with the length of "self._Cursor" this is the real amount of bytes that has data in it
	local _b = buffer.create(self._Cursor)
	local instances = self._instances
	--copies data from the buffer over to this newly created buffer from 0 till "self._Cursor"
	buffer.copy(_b, 0, self._buffer, 0, self._Cursor)
	-- reset cursor position
	self._Cursor = 0

	-- sets capacity back to the default capacity

	self._instances = {}

	if self._capacity > SHRINK_CAP then
		--create new buffer with 'INIT_CAP' the default
		self._buffer = buffer.create(INIT_CAP)
		self._capacity = INIT_CAP
	end
	return _b, instances
end

local function GetCursorCount(self: Writer)
	local count = self._Cursor
	return count
end

local function SerializeMany<T...>(self: Writer, fieldCount: number, writeFns: { (...any) -> () }, ...: T...)
	local packValues = table.pack(...)

	if fieldCount ~= packValues.n then
		error(string.format("expected %d args, got %d", fieldCount, packValues.n), 4)
		return
	end

	for i, func in writeFns do
		func(self, packValues[i])
	end
end

return {
	New = New,
	Reserve = Reserve,
	SerializeMany = SerializeMany,
	GetCursorCount = GetCursorCount,
	Dump = Dump,
}
