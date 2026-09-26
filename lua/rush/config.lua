local M = {}

local default_config = {
	log = {
		level = vim.log.levels.ERROR,
		output = "file", -- "buffer", "file", "print", "notify"
		buffer_name = "rush://log",
		file_name = "/tmp/rush.log",
		use_timestamp = false,
		single_line = true,
		probe = true,
		monitor = false,
	},
}

function M.setup(opts)
	local config =
		vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
	for key, value in pairs(config) do
		M[key] = value
	end
end

return M
