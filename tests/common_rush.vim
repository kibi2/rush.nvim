lua << EOF
local root = assert(os.getenv("KIBI2_REPO_ROOT"))

vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(root .. "/../keyevent.nvim")
EOF