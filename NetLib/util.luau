local function GetFullChannelName(namespace, channelName)
	return tostring(namespace) .. "." .. tostring(channelName)
end

return {
	GetFullChannelName = GetFullChannelName,
}
