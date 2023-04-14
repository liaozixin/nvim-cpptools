local plugin_path =  debug.getinfo(1, 'S').source:sub(2)
plugin_path = vim.fn.fnamemodify(plugin_path, ':h')

local function clear_cmd()
    vim.cmd([[normal! :\<C-u>]])
end

-- local function dirlist(path)
--     local handle = io.popen("python " .. plugin_path .. "/dirlist.py " .. path)
--     local path_str = handle:read("*a")
--     local path_list = {}
--     for s in string.gmatch(path_str, "[^;]+") do
--         table.insert(path_list, s)
--     end
--     for key, value in pairs(path_list) do
--         print(value)
--     end
--     handle:close()
-- end

local function makedirs(path)
    print(path)
    if not path then
        return nil
    end
    vim.fn.mkdir(path)
end

local function isdir(path)
    if not path then
        return nil
    end
    if vim.fn.isdirectory(path) == 1 then
        return true
    else
        return false
    end
    -- local handle = io.popen("python " .. plugin_path .. "/isdir.py " .. path)
    -- local res = handle:read("*a")
    -- if string.find(res, "true") then
    --     return true
    -- else 
    --     return false
    -- end
    -- handle:close()
end

local function hasfile(path)
    if not path then
        return nil
    end
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

local function test()
    print("test")
end

return{
    -- dirlist = dirlist,
    makedirs = makedirs,
    clear_cmd = clear_cmd,
    isdir = isdir,
    hasfile = hasfile,
    test = test,
}
