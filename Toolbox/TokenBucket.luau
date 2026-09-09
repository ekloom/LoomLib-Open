--!strict
local Players = game:GetService("Players")
local TokenBucket = {}

TokenBucket.__index = TokenBucket

export type refillMode = "time" | "none"

type tokenData = {
	lastRefillTime: number,
	tokens: number,
}

export type TokenBucket = typeof(setmetatable(
	{} :: {
		entries: { [Player]: tokenData },
		capacity: number,
		refillRate: number,
		refillMode: refillMode,
		removingConnection: RBXScriptConnection,
	},
	TokenBucket
))

function TokenBucket.New(refillMode: refillMode, capacity, refillRate)
	local self = setmetatable({}, TokenBucket) :: TokenBucket

	self.capacity = capacity
	self.refillRate = refillRate
	self.refillMode = refillMode
	self.entries = {}
	self.removingConnection = Players.PlayerRemoving:Connect(function(player)
		self:RemovePlayer(player)
	end)
	return self
end

local function _getOrCreateBucket(self, player)
	if not self.entries[player] then
		if self.refillMode == "none" then
			error("Player has no entry! Call SetPlayer first for 'none' mode buckets")
		end
		self.entries[player] = { lastRefillTime = 0, tokens = self.capacity }
	end
	return self.entries[player]
end

local function _calculateCurrentTokens(self: TokenBucket, entry: tokenData, now: number): number
	if self.refillMode == "time" then
		return math.min(self.capacity, ((now - entry.lastRefillTime) * self.refillRate) + entry.tokens)
	end
	return entry.tokens
end

function TokenBucket.SetPlayer(self: TokenBucket, player: Player, tokens, lastRefillTime: number?)
	if self.entries[player] then
		error("Duplicate entry found!\nThe player data has already been stored!")
	end
	if self.refillMode == "time" and lastRefillTime == nil then
		error("Last refilltime is needed in time mode!")
	end

	self.entries[player] = { lastRefillTime = lastRefillTime, tokens = tokens }
end

function TokenBucket.GetPlayer(self: TokenBucket, player: Player): (number?, number?)
	local entry = self.entries[player]
	if not entry then
		return nil
	end

	local currentTokens = _calculateCurrentTokens(self, entry, os.clock())
	return currentTokens, entry.lastRefillTime
end

function TokenBucket.Consume(self: TokenBucket, player: Player, cost: number): (boolean, number)
	assert(type(cost) == "number", "cost must be a number")
	assert(cost >= 0, "cost must be non-negative")

	local entry = _getOrCreateBucket(self, player)
	local now = os.clock()

	entry.tokens = _calculateCurrentTokens(self, entry, now)
	if self.refillMode == "time" then
		entry.lastRefillTime = now
	end

	if entry.tokens < cost then
		return false, entry.tokens
	end

	entry.tokens -= cost
	return true, entry.tokens
end

function TokenBucket.RemovePlayer(self: TokenBucket, player: Player)
	self.entries[player] = nil
end

function TokenBucket.Destroy(self: TokenBucket)
	self.removingConnection:Disconnect()
	self.entries = {}
end

return TokenBucket
