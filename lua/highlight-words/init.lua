local function setup(opts)
    require("highlight-words.config").setup(opts)
    require("highlight-words.highlight").setup()
end

return { setup = setup }
