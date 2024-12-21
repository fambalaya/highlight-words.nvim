local defaul_opts = {
    patterns = {
        {
            filter = {
                filetype = {
                    "c",
                    "cpp",
                    "lua",
                    "python",
                    "markdown",
                    "sh",
                    "yang",
                    "toml",
                    "yaml",
                    "bzl",
                    "cmake",
                    "conf",
                    "dosini",
                },
            },
            pattern = { "0[xX]%x+", "%x+", "[_%a][_%w]*", "%d*%.%d*" },
        },
        {
            filter = { filetype = { "c", "cpp" } },
            pattern = { "%d+[uU][lL]*" },
        },
        {
            filter = { filetype = { "yang" } },
            pattern = { "[_%w-]+" },
        },
    },
    colors = {
        { light = { fg = "#000000", bg = "#00FF00" }, dark = { fg = "#FFFFFF", bg = "#4875BF" } },
        { light = { fg = "#000000", bg = "#BF3EFF" }, dark = { fg = "#FFFFFF", bg = "#A115A1" } },
        { light = { fg = "#000000", bg = "#00FA9A" }, dark = { fg = "#FFFFFF", bg = "#C27E08" } },
        { light = { fg = "#000000", bg = "#00FFFF" }, dark = { fg = "#FFFFFF", bg = "#178F63" } },
        { light = { fg = "#000000", bg = "#FF7F00" }, dark = { fg = "#FFFFFF", bg = "#B15E3E" } },
        { light = { fg = "#000000", bg = "#FF0000" }, dark = { fg = "#FFFFFF", bg = "#26831C" } },
        { light = { fg = "#000000", bg = "#FFD700" }, dark = { fg = "#FFFFFF", bg = "#196983" } },
    },
}

local M = { opts = defaul_opts }

---@param opts table
function M.setup(opts) M.opts = vim.tbl_deep_extend("force", defaul_opts, opts) end

return M
