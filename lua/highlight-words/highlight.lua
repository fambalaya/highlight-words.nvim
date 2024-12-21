local config = require("highlight-words.config")
local api = vim.api
local fn = vim.fn

local M = {}
local g = {
    enabled = false, ---@type boolean
    bufs = {}, ---@type table<string, true>
    words = {}, ---@type table<string, table<string, integer>>
    next_color_id = 1, ---@type integer
    color_cnt = nil,
}

---@param id integer?
---@return string
local function hl_group_name(id)
    if not id then
        id = g.next_color_id
        g.next_color_id = id == g.color_cnt and 1 or id + 1
    end
    return string.format("highlight-words.nvim-%d", id)
end

local function map_from_list(t)
    local r = {}
    for i, v in ipairs(t) do
        r[v] = i
    end
    return r
end

---@param buf integer
---@return table|nil, string?
local function get_pattern_tbl(buf)
    local function match(filter)
        if type(filter) == "function" then return filter(buf) end
        assert(type(filter) == "table")
        for k, v in pairs(filter) do
            local buf_opt = api.nvim_get_option_value(k, { buf = buf })
            if type(v) == "string" then
                if buf_opt ~= v then return false end
            else
                local m = map_from_list(v)
                if not m[buf_opt] then return false end
            end
        end
        return true
    end

    local ot = {}
    for _, t in ipairs(config.opts.patterns) do
        if match(t.filter) then
            for _, a in ipairs(t.pattern) do
                table.insert(ot, a)
            end
        end
    end
    if #ot == 0 then
        local file_type = api.nvim_get_option_value("filetype", { buf = buf })
        return nil, file_type
    end
    return ot
end

---@param pattern string[]
---@return string|nil
local function get_normal_word(pattern)
    local line = api.nvim_get_current_line()
    local _, pos = unpack(api.nvim_win_get_cursor(0))
    pos = pos + 1 -- Start from 1
    local function each(pt)
        local start = 1
        repeat
            local a, b = line:find(pt, start)
            if not a then return end
            if a <= pos and pos <= b then return line:sub(a, b) end
            start = b + 1
        until a > pos
    end
    local word
    for _, pt in ipairs(pattern) do
        local w = each(pt)
        if w then
            if not word then word = w end
            if #w > #word then word = w end
        end
    end
    return word
end

---@return string
local function get_visual_str()
    local _, ls, cs = unpack(vim.fn.getpos("v"))
    local _, le, ce = unpack(vim.fn.getpos("."))
    local t = api.nvim_buf_get_text(0, ls - 1, cs - 1, le, ce, {})
    return table.concat(t, "\n")
end

---@return string|nil, string?
local function get_word()
    local mode = vim.fn.mode()
    if mode == "v" then
        local s = get_visual_str()
        if s == "" then return nil, "No word found!" end
        return s
    end
    -- mode n, i
    local buf = api.nvim_win_get_buf(0)
    local pt, ft = get_pattern_tbl(buf)
    if not pt then return nil, string.format("No pattern found for %s", ft) end
    local word = get_normal_word(pt)
    if not word then return nil, "No word found!" end
    word = "\\<" .. word .. "\\>"
    return word
end

local function each_win(f)
    local wins = api.nvim_list_wins()
    for _, win in ipairs(wins) do
        local buf = api.nvim_win_get_buf(win)
        if g.bufs[buf] then f(win) end
    end
end

local function highlight_on(word)
    local add = fn.matchadd
    local t = g.words[word] or { group = hl_group_name() }
    local group = t.group
    each_win(function(win)
        if t[win] then return end
        local id = add(group, word, 11, -1, { window = win })
        t[win] = id
    end)
    g.words[word] = t
end

local function highlight_off(word)
    local delete = fn.matchdelete
    local t = g.words[word]
    if not t then return end
    each_win(function(win)
        local id = t[win]
        if id then delete(id, win) end
    end)
    g.words[word] = nil
end

local function toggle()
    local word, err = get_word()
    if not word then
        return vim.notify(err, vim.log.levels.INFO)
    end
    if g.words[word] then
        highlight_off(word)
    else
        highlight_on(word)
    end
end

local function clear()
    each_win(fn.clearmatches)
    g.words = {}
    g.next_color_id = 1
end

local function install_cmd()
    local new_cmd = api.nvim_create_user_command
    new_cmd("HighlightToggle", toggle, {})
    new_cmd("HighlightClear", clear, {})
end

local function on_new_buf(buf)
    if g.bufs[buf] then return end
    if not (api.nvim_buf_is_loaded(buf) and api.nvim_buf_is_valid(buf)) then return end
    local pt = get_pattern_tbl(buf)
    if not pt then return end
    g.bufs[buf] = true
end

local function on_del_buf(buf) g.bufs[buf] = nil end

local function on_new_win()
    for word, _ in pairs(g.words) do
        highlight_on(word)
    end
end

local function create_hl_groups()
    local set_hl = api.nvim_set_hl
    for i, t in ipairs(config.opts.colors) do
        local bg = vim.o.background
        local hl = assert(t[bg])
        local name = hl_group_name(i)
        set_hl(0, name, hl)
    end
    g.color_cnt = #config.opts.colors
end

local function on_colorscheme() create_hl_groups() end

local function install_autocmd()
    local group = api.nvim_create_augroup("highlight-words.nvim", {})
    api.nvim_create_autocmd({ "BufRead", "WinNew", "BufAdd", "BufEnter", "BufNew", "FileType" }, {
        group = group,
        callback = function(event) return on_new_buf(event.buf) end,
    })
    api.nvim_create_autocmd({ "BufDelete", "BufUnload", "BufLeave", "BufWinLeave" }, {
        group = group,
        callback = function(event) return on_del_buf(event.buf) end,
    })
    api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
        group = group,
        callback = on_new_win,
    })
    api.nvim_create_autocmd({ "ColorScheme" }, {
        group = group,
        callback = on_colorscheme,
    })
end

local function setup()
    if g.enabled then return end
    g.enabled = true
    g.next_color_id = 1

    install_cmd()
    install_autocmd()
    create_hl_groups()

    local bufs = api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
        on_new_buf(buf)
    end
end

return { setup = setup }
