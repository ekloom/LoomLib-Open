--!optimize 2
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Writer = require(ReplicatedStorage.LoomLib.NetLib.Writer)

local Reserve = Writer.Reserve

export type Codec<T> = {
	Name: string,
	Deserialize: (buffer, number, any?, any?) -> (T, number),
	Serialize: (Writer.Writer, T) -> (),
}

local function defineType<T>(spec: Codec<T>): T
	return (spec :: any) :: T
end

local NetLibType = {}

function NetLibType.asFormat<T>(phantom: T): Codec<T>
	return (phantom :: any) :: Codec<T>
end

NetLibType.uint8 = defineType({
	Name = "uint8",
	Deserialize = function(b, offset)
		return buffer.readu8(b, offset), offset + 1
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 1)
		buffer.writeu8(b, offset, value)
	end,
})

NetLibType.uint16 = defineType({
	Name = "uint16",
	Deserialize = function(b, offset)
		return buffer.readu16(b, offset), offset + 2
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 2)
		buffer.writeu16(b, offset, value)
	end,
})

NetLibType.uint32 = defineType({
	Name = "uint32",
	Deserialize = function(b, offset)
		return buffer.readu32(b, offset), offset + 4
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 4)
		buffer.writeu32(b, offset, value)
	end,
})

NetLibType.int8 = defineType({
	Name = "int8",
	Deserialize = function(b, offset)
		return buffer.readi8(b, offset), offset + 1
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 1)
		buffer.writei8(b, offset, value)
	end,
})

NetLibType.int16 = defineType({
	Name = "int16",
	Deserialize = function(b, offset)
		return buffer.readi16(b, offset), offset + 2
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 2)
		buffer.writei16(b, offset, value)
	end,
})

NetLibType.int32 = defineType({
	Name = "int32",
	Deserialize = function(b, offset)
		return buffer.readi32(b, offset), offset + 4
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 4)
		buffer.writei32(b, offset, value)
	end,
})

NetLibType.float32 = defineType({
	Name = "float32",
	Deserialize = function(b, offset)
		return buffer.readf32(b, offset), offset + 4
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 4)
		buffer.writef32(b, offset, value)
	end,
})
NetLibType.float64 = defineType({
	Name = "float64",
	Deserialize = function(b, offset)
		return buffer.readf64(b, offset), offset + 8
	end,
	Serialize = function(writer, value)
		local b, offset = Reserve(writer, 8)
		buffer.writef64(b, offset, value)
	end,
})

-- length of 255 characters max
NetLibType.string = defineType({
	Name = "string",
	Deserialize = function(b, offset)
		local count = buffer.readu8(b, offset)
		return buffer.readstring(b, offset + 1, count), offset + 1 + count
	end,
	Serialize = function(writer, value)
		local length = value:len()

		if length > 255 or length <= 0 then
			return
		end

		local b, offset = Reserve(writer, 1 + length)
		buffer.writeu8(b, offset, length)
		buffer.writestring(b, offset + 1, value)
	end,
})

NetLibType.vec3 = defineType({
	Name = "Vector3",
	Deserialize = function(b, offset)
		local x = buffer.readf32(b, offset)
		local y = buffer.readf32(b, offset + 4)
		local z = buffer.readf32(b, offset + 8)
		return Vector3.new(x, y, z), offset + 12
	end,
	Serialize = function(writer, value)
		if typeof(value) ~= "Vector3" then
			error(string.format("Serialize: expected Vector3, got %s", typeof(value)))
		end
		local b, offset = Reserve(writer, 12)
		buffer.writef32(b, offset, value.X)
		buffer.writef32(b, offset + 4, value.Y)
		buffer.writef32(b, offset + 8, value.Z)
	end,
})
NetLibType.cframe = defineType({
	Name = "cframe",
	Deserialize = function(b, offset)
		local x = buffer.readf32(b, offset)
		local y = buffer.readf32(b, offset + 4)
		local z = buffer.readf32(b, offset + 8)

		local r00 = buffer.readf32(b, offset + 12)
		local r01 = buffer.readf32(b, offset + 16)
		local r02 = buffer.readf32(b, offset + 20)

		local r10 = buffer.readf32(b, offset + 24)
		local r11 = buffer.readf32(b, offset + 28)
		local r12 = buffer.readf32(b, offset + 32)

		local r20 = buffer.readf32(b, offset + 36)
		local r21 = buffer.readf32(b, offset + 40)
		local r22 = buffer.readf32(b, offset + 44)
		return CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22), offset + 48
	end,
	Serialize = function(writer, value)
		if typeof(value) ~= "CFrame" then
			error(string.format("Serialize: expected CFrame, got %s", typeof(value)))
		end
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
		local b, offset = Reserve(writer, 48)
		buffer.writef32(b, offset, x)
		buffer.writef32(b, offset + 4, y)
		buffer.writef32(b, offset + 8, z)

		buffer.writef32(b, offset + 12, r00)
		buffer.writef32(b, offset + 16, r01)
		buffer.writef32(b, offset + 20, r02)

		buffer.writef32(b, offset + 24, r10)
		buffer.writef32(b, offset + 28, r11)
		buffer.writef32(b, offset + 32, r12)

		buffer.writef32(b, offset + 36, r20)
		buffer.writef32(b, offset + 40, r21)
		buffer.writef32(b, offset + 44, r22)
	end,
})

NetLibType.LossyCFrame = defineType({
	Name = "LossyCFrame",
	Deserialize = function(b, offset)
		local pos = Vector3.new(buffer.readf32(b, offset), buffer.readf32(b, offset + 4), buffer.readf32(b, offset + 8))
		local axisVec3 =
			Vector3.new(buffer.readf32(b, offset + 12), buffer.readf32(b, offset + 16), buffer.readf32(b, offset + 20))
		local angle = buffer.readf32(b, offset + 24)

		return CFrame.fromAxisAngle(axisVec3, angle) + pos, offset + 28
	end,
	Serialize = function(writer, value)
		if typeof(value) ~= "CFrame" then
			error(string.format("Serialize: expected CFrame, got %s", typeof(value)))
		end
		local axis, angle = value:ToAxisAngle()
		local b, offset = Reserve(writer, 28)
		buffer.writef32(b, offset, value.X)
		buffer.writef32(b, offset + 4, value.Y)
		buffer.writef32(b, offset + 8, value.Z)
		buffer.writef32(b, offset + 12, axis.X)
		buffer.writef32(b, offset + 16, axis.Y)
		buffer.writef32(b, offset + 20, axis.Z)
		buffer.writef32(b, offset + 24, angle)
	end,
})

NetLibType.boolean = defineType({
	Name = "boolean",
	Deserialize = function(b, offset)
		local result = buffer.readu8(b, offset)
		local _v = result ~= 0
		return _v, offset + 1
	end,
	Serialize = function(writer, value)
		if type(value) ~= "boolean" then
			error(string.format("Serialize: expected boolean, got %s", type(value)))
		end
		local b, offset = Reserve(writer, 1)
		buffer.writeu8(b, offset, value and 1 or 0)
	end,
})
NetLibType.color3 = defineType({
	Name = "color3",
	Deserialize = function(b, offset)
		return Color3.fromRGB(buffer.readu8(b, offset), buffer.readu8(b, offset + 1), buffer.readu8(b, offset + 2)),
			offset + 3
	end,
	Serialize = function(writer, value)
		if typeof(value) ~= "Color3" then
			error(string.format("Serialize: expected Color3, got %s", typeof(value)))
		end
		local b, offset = Reserve(writer, 3)
		buffer.writeu8(b, offset, value.R * 255 + 0.5)
		buffer.writeu8(b, offset + 1, value.G * 255 + 0.5)
		buffer.writeu8(b, offset + 2, value.B * 255 + 0.5)
	end,
})
NetLibType.vec2 = defineType({
	Name = "Vector2",
	Deserialize = function(b, offset)
		local x = buffer.readf32(b, offset)
		local y = buffer.readf32(b, offset + 4)
		return Vector2.new(x, y), offset + 8
	end,
	Serialize = function(writer, value)
		if typeof(value) ~= "Vector2" then
			error(string.format("Serialize: expected Vector2, got %s", typeof(value)))
		end
		local b, offset = Reserve(writer, 8)
		buffer.writef32(b, offset, value.X)
		buffer.writef32(b, offset + 4, value.Y)
	end,
})
NetLibType.string16 = defineType({
	Name = "string16",
	Deserialize = function(b, offset)
		local count = buffer.readu16(b, offset)
		return buffer.readstring(b, offset + 2, count), offset + 2 + count
	end,
	Serialize = function(writer, value)
		local length = value:len()
		if length > 65535 or length <= 0 then
			return
		end
		local b, offset = Reserve(writer, 2 + length)
		buffer.writeu16(b, offset, length)
		buffer.writestring(b, offset + 2, value)
	end,
})

-- angle8: one byte for an angle in radians. ~1.4° precision.
-- Cardinal angles (0, 45, 90, 135, 180, 225, 270, 315 degrees) snap exactly.
do
	local rad2 = math.pi * 2
	local angle8range = math.rad(359)

	local function encode(rad: number)
		return math.round((rad % rad2) * 255 / angle8range)
	end

	local decodeLookup = {}
	for i = 0, 255 do
		decodeLookup[i] = i * angle8range / 255
	end
	for deg = 0, 315, 45 do
		local r = math.rad(deg)
		decodeLookup[encode(r)] = r
	end

	NetLibType.angle8 = defineType({
		Name = "angle8",
		Deserialize = function(b, offset)
			return decodeLookup[buffer.readu8(b, offset)], offset + 1
		end,
		Serialize = function(writer, value)
			local b, offset = Reserve(writer, 1)
			buffer.writeu8(b, offset, encode(value))
		end,
	})
end

--[[

	Definition time validation: fields must be a non empty array of
	{name = string, format = Codec
} entries. Names must be unique.

	Wire order matches, field definition order and Field order matters.
]]
function NetLibType.struct<T>(fields: { { name: string, format: any } }): T
	if type(fields) ~= "table" or #fields == 0 then
		error("NetLibType.struct expects a non-empty array of {name, format} entries")
	end

	local fieldCount = #fields
	local keys = table.create(fieldCount)
	local writeFns = table.create(fieldCount)
	local readFns = table.create(fieldCount)
	local nullable = table.create(fieldCount)

	local fieldNames = {}
	for i, entry in ipairs(fields) do
		if type(entry) ~= "table" or type(entry.name) ~= "string" or entry.format == nil then
			error(string.format("NetLibType.struct: field %d must be {name = string, format = Codec}", i))
		end
		if fieldNames[entry.name] then
			error(string.format("NetLibType.struct: duplicate field name '%s'", entry.name))
		end

		local f = entry.format

		if typeof(f) ~= "table" or typeof(f.Serialize) ~= "function" or typeof(f.Deserialize) ~= "function" then
			error(string.format("NetLibType.struct: field '%s' format is not a valid Codec", entry.name), 2)
		end
		if (f :: any).__isStruct then
			error(string.format("NetLibType.struct: field '%s' is a nested struct (not supported)", entry.name))
		end

		fieldNames[entry.name] = true

		keys[i] = entry.name
		writeFns[i] = entry.format.Serialize
		readFns[i] = entry.format.Deserialize
		nullable[i] = (f :: any).__isNullable == true
	end

	local spec
	spec = {
		Name = "struct",
		__isStruct = true,

		Serialize = function(writer, value)
			for i = 1, fieldCount do
				local v = value[keys[i]]
				if v == nil and not nullable[i] then
					error("struct: missing required field '" .. keys[i] .. "' (verify table contents and spelling)")
				end
				writeFns[i](writer, v)
			end
		end,

		Deserialize = function(b, offset, context)
			local result = {}
			for i = 1, fieldCount do
				result[keys[i]], offset = readFns[i](b, offset, context)
			end
			return result, offset
		end,
	}

	return (spec :: any) :: T
end
NetLibType.instance = defineType({
	Name = "instance",
	__isNullable = true,
	__zeroSize = true,
	Deserialize = function(_, offset, context)
		if not context then
			return nil :: any, offset
		end
		local ctx = context :: { instances: { Instance }, cursor: number }
		local _v = ctx.instances[context.cursor]

		context.cursor += 1
		if (_v :: any) == false then
			return nil, offset
		end

		return _v :: Instance, offset
	end,
	Serialize = function(writer, value: any?)
		local instances = writer._instances

		local _count = #instances
		if value == nil then
			instances[_count + 1] = false
		else
			instances[_count + 1] = value
		end
	end,
} :: Codec<Instance?>)

function NetLibType.array<T>(format: T, maxLength: number?): { T }
	if
		typeof(format) ~= "table"
		or typeof(format.Serialize) ~= "function"
		or typeof(format.Deserialize) ~= "function"
	then
		error("NetLibType.array expects a valid Codec")
	end

	local max = maxLength or 256

	local writeFn = format.Serialize
	local readFn = format.Deserialize
	--  flag check for no buffer entrance type
	local elementZeroSize = format.__zeroSize == true

	local lengthSize
	local writeLength
	local readLength

	if max <= 0xFF then
		lengthSize = 1
		writeLength = buffer.writeu8
		readLength = buffer.readu8
	elseif max <= 0xFFFF then
		lengthSize = 2
		writeLength = buffer.writeu16
		readLength = buffer.readu16
	else
		lengthSize = 4
		writeLength = buffer.writeu32
		readLength = buffer.readu32
	end

	local spec = {
		Name = "array",

		Deserialize = function(b, offset, context)
			local length = readLength(b, offset)

			offset += lengthSize

			if length > max then
				error(("Received array length %d exceeds maximum of %d"):format(length, max))
			end

			-- my heart pounding rn (ಠ_ಠ)
			if not elementZeroSize then
				local remaining = buffer.len(b) - offset
				if length > remaining then
					error(("Array length %d exceeds remaining buffer bytes %d"):format(length, remaining))
				end
			end

			local result = table.create(length)

			for i = 1, length do
				result[i], offset = readFn(b, offset, context)
			end

			return result, offset
		end,

		Serialize = function(writer, value)
			if type(value) ~= "table" then
				error("NetLibType.array.Serialize expects a table")
			end

			local length = #value

			if length > max then
				error(("Array length %d exceeds maximum of %d"):format(length, max))
			end

			local b, offset = Reserve(writer, lengthSize)
			writeLength(b, offset, length)

			for i = 1, length do
				writeFn(writer, value[i])
			end
		end,
	}

	return (spec :: any) :: { T }
end
NetLibType.optional = function<T>(format: T): T?
	local f = format :: any
	if typeof(f) ~= "table" or typeof(f.Serialize) ~= "function" or typeof(f.Deserialize) ~= "function" then
		error(string.format("NetLibType.optional: field '%s' format is not a valid Codec", f.name), 2)
	end

	local writeFn = f.Serialize
	local readFns = f.Deserialize

	local u8Write = NetLibType.asFormat(NetLibType.uint8).Serialize
	local u8Read = NetLibType.asFormat(NetLibType.uint8).Deserialize

	local spec = {
		Name = "optional",
		__isNullable = true,
		__isStruct = f.__isStruct,

		Deserialize = function(buffer, offset, context)
			local hasValue, _offset = u8Read(buffer, offset)

			if hasValue == 0 then
				return nil, _offset
			end

			local result, resultOffset = readFns(buffer, _offset, context)

			return result, resultOffset
		end,
		Serialize = function(writer, value)
			if value == nil then
				u8Write(writer, 0)
				return
			end
			u8Write(writer, 1)
			writeFn(writer, value)
		end,
	}

	return (spec :: any) :: T?
end

function NetLibType.Dictionary<K, V>(keyType: K, valueType: V, maxLength: number?): { [K]: V }
	if
		typeof(valueType) ~= "table"
		or typeof(valueType.Serialize) ~= "function"
		or typeof(valueType.Deserialize) ~= "function"
		or typeof(keyType) ~= "table"
		or typeof(keyType.Serialize) ~= "function"
		or typeof(keyType.Deserialize) ~= "function"
	then
		error("NetLibType.Dictionary expects a valid Codec")
	end

	if (keyType :: any).__isNullable then
		error("NetLibType.Dictionary: key codec cannot be nullable (optional or instance)")
	end

	local max = maxLength or 256

	local writeKeyFn = keyType.Serialize
	local readKeyFn = keyType.Deserialize
	local writeValueFn = valueType.Serialize
	local readValueFn = valueType.Deserialize
	--  flag check for no buffer entrance type
	local elementZeroSize = keyType.__zeroSize == true or valueType.__zeroSize

	local lengthSize
	local writeLength
	local readLength

	if max <= 0xFF then
		lengthSize = 1
		writeLength = buffer.writeu8
		readLength = buffer.readu8
	elseif max <= 0xFFFF then
		lengthSize = 2
		writeLength = buffer.writeu16
		readLength = buffer.readu16
	else
		lengthSize = 4
		writeLength = buffer.writeu32
		readLength = buffer.readu32
	end

	local spec = {
		Name = "dictionary",
		Deserialize = function(b, offset, context)
			local length = readLength(b, offset)

			offset += lengthSize

			if length > max then
				error(("Received Dictionary length %d exceeds maximum of %d"):format(length, max))
			end

			-- my heart pounding rn (ಠ_ಠ)
			-- flag for if data is coming from the buffer or if it's an instance
			if not elementZeroSize then
				local remaining = buffer.len(b) - offset
				if length > remaining then
					error(("Dictionary length %d exceeds remaining buffer bytes %d"):format(length, remaining))
				end
			end

			local result = table.create(length)

			for _ = 1, length do
				local keyResult, _offset = readKeyFn(b, offset, context)
				if keyResult == nil then
					error("Dictionary: deserialized a nil key")
				end
				local valueResult, lastOffset = readValueFn(b, _offset, context)
				offset = lastOffset
				result[keyResult] = valueResult
			end
			return result, offset
		end,

		Serialize = function(writer, value)
			if type(value) ~= "table" then
				error("NetLibType.Dictionary.Serialize expects a table")
			end

			-- length per entry
			local length = 0
			for _ in pairs(value) do
				length += 1
			end

			if length > max then
				error(("Dictionary length %d exceeds maximum of %d"):format(length, max))
			end

			local b, offset = Reserve(writer, lengthSize)
			writeLength(b, offset, length)

			for key, val in pairs(value) do
				writeKeyFn(writer, key)
				writeValueFn(writer, val)
			end
		end,
	}

	return (spec :: any) :: { [K]: V }
end

export type NetLibType<T> = typeof(NetLibType)

return NetLibType
