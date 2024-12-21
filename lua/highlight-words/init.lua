
local function setup(opts)
    require('highlight-words.config').setup(opts)
    require('highlight-words.highlight').setup(opts)
end
return { setup = setup }
