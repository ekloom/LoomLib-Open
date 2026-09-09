local ChannelTypes = require(script.Parent.ChannelTypes)

export type NamespaceConfig = {
	excludeFromRateLimit: boolean?,
	ChannelConfig: ChannelTypes.ChannelConfig?,
}

export type NamespaceData = {
	namespaceName: string,
	NamespaceConfig: NamespaceConfig,
}

return {}
