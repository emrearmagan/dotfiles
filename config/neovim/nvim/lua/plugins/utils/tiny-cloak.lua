return {
	"jellydn/tiny-cloak.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		cloak_character = "*", -- Masking character, default
		file_patterns = { ".env*", "*.json", "*.yaml", "*.yml" }, -- File patterns to cloak
		key_patterns = { ".*_API_KEY", ".*_SECRET", ".*_PASSWORD", ".*_TOKEN", ".*_CREDENTIAL", ".*_AUTH", ".*_APIKEY" }, -- Extended key patterns for cloaking
	},
}
