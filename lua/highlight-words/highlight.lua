local default_opts = {
    keymaps = {
        toggle = "<M-a>",
        clear = "<M-c>",
    },
    colors = {},
}
local cmd_mode = { "n", "i", "v" }
local cur_opts

local function toggle() vim.print("toggle 123123") end

local function clear() vim.print("clear") end

local function uninstall_keymap(opts)
    local keymaps = opts.keymaps
    if not keymaps then return end

    local del = vim.keymap.del
    for _, t in pairs(keymaps) do
        if type(t) ~= "table" then t = { t } end
        for _, a in ipairs(t) do
            del(cmd_mode, a)
        end
    end
end

local function install_keymap(opts)
    local keymaps = opts.keymaps
    if not keymaps then return end

    local set = vim.keymap.set
    local opt = { remap = false, silent = true }

    local m = { toggle = toggle, clear = clear }
    for k, f in pairs(m) do
        local t = keymaps[k]
        if type(t) ~= "table" then t = { t } end
        for _, a in ipairs(t) do
            set(cmd_mode, a, f, opt)
        end
    end
end

local function load() install_keymap(default_opts) end

local function setup(opts)
    cur_opts = vim.tbl_deep_extend("force", default_opts, opts)
    uninstall_keymap(default_opts)
    install_keymap(cur_opts)
end
return { load = load, setup = setup }
