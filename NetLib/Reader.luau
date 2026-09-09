--!optimize 2

local function readManyAt(
	buf: buffer,
	context: { instances: { Instance }, cursor: number }?,
	fieldCount: number,
	readFns: { (buffer, number) -> (any, number) },
	startCursor: number?
): ({ any }, number, number)
	local cursor = startCursor or 0
	local results = table.create(fieldCount)

	for i, func in readFns do
		results[i], cursor = func(buf, cursor, context)
	end
	return results, cursor, fieldCount
end

local function readMany(
	buf: buffer,
	context: { instances: { Instance }, cursor: number }?,
	fieldCount: number,
	readFns: { (buffer, number) -> (any, number) },
	startCursor: number?
): ...any
	local cursor = startCursor or 0
	local results = table.create(fieldCount)

	for i, func in readFns do
		results[i], cursor = func(buf, cursor, context)
	end

	return table.unpack(results, 1, fieldCount)
end

local function readOne<T>(buf: buffer, readFn: (buffer, number) -> (T, number), startCursor: number?): (T, number)
	local cursor = startCursor or 0
	return readFn(buf, cursor)
end

local function HasExceededBufferLimit(_buffer, _maxCapacity): boolean
	return buffer.len(_buffer) > _maxCapacity
end

return {

	readManyAt = readManyAt,
	readMany = readMany,
	readOne = readOne,
	HasExceededBufferLimit = HasExceededBufferLimit,
}
