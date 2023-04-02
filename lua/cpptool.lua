local parsers = require('nvim-treesitter.parsers')
local utils = require('utils')


local current_dir = vim.api.nvim_call_function('getcwd', {})
current_dir = string.gsub(current_dir, [[\]], "/")
current_dir = current_dir .. "/"

local function _cf(file_name, file_type, path)
    local file
    local str
    if file_type then
        file = io.open(path..file_name.."."..file_type, "a+")
        str = file_name .. "." ..file_type
    else
        file = io.open(path..file_name, "a+")
        str = file_name
    end
    if not file then
        vim.notify("create file error!", "error", {
            title = "error"
        })
        return
    end
    if file_type == "h" or file_type == "hpp" then
        file:write("#pragma once\n")
        file:write("#ifndef _"..string.upper(file_name).."_"..string.upper(file_type).."_\n")
        file:write("#define _"..string.upper(file_name).."_"..string.upper(file_type).."_\n")
        file:write("\n")
        file:write("\n")
        file:write("#endif")
    elseif file_type == "c" then
        if utils.hasfile(path..file_name..".h") then
            file:write([[#include "]]..file_name..".h"..[["]].."\n")
        end
    elseif file_type == "cpp" then
        if utils.hasfile(path..file_name..".hpp") then
            file:write([[#include "]]..file_name..".hpp"..[["]].."\n")
        elseif utils.hasfile(path..file_name..".h") then
            file:write([[#include "]]..file_name..".h"..[["]].."\n")
        end
    end
    io.close(file)
    vim.notify(path..str, "info", {
        title = "Create file!",
    })
end

local function create_file()
    local input = vim.fn.input("Create file ", current_dir)
    utils.clear_cmd()

    local file_name = string.match(input, ".+/([^/]+)$")
    if input == "" then
        return
    end
    if not file_name and not utils.isdir(input) then
        utils.makedirs(input)
        vim.notify(input, "info",{
            title = "create dir!"
        })
        return
    end

    local file_type = file_name:match("%.([^%.]+)$")
    file_name = file_name:match("(.+)%..+") or file_name
    local path = input:match("(.*/)")

    if file_name then
        if utils.isdir(path) then
            _cf(file_name, file_type, path)
        else
            utils.makedirs(path) 
            _cf(file_name, file_type, path)
        end
    end
end

local function traverse_node(node, parent_node, n_info, c_info)
    if node:type() == "identifier" and node:parent():type() == "namespace_definition" then
        local namespace = {}
        local b_r, b_c, e_r, e_c = node:range()
        local namespace_name = vim.api.nvim_buf_get_lines(0, b_r, e_r + 1, null)[1]:sub(b_c, e_c)
        b_r, b_c, e_r, e_c = node:parent():range()
        local range = {b_r + 1, e_r + 1}
        namespace[1] = namespace_name
        namespace[2] = range[1]
        namespace[3] = range[2]
        table.insert(n_info, namespace)
    elseif node:type() == "type_identifier" and node:parent():type() == "class_specifier" then
        local class = {}
        local b_r, b_c, e_r, e_c = node:range()
        local class_name = vim.api.nvim_buf_get_lines(0, b_r, e_r + 1, null)[1]:sub(b_c, e_c)
        b_r, b_c, e_r, e_c = node:parent():range()
        local range = {b_r + 1, e_r + 1}
        class[1] = class_name
        class[2] = range[1]
        class[3] = range[2]
        table.insert(c_info, class)
    end
    for child_node in node:iter_children() do
        traverse_node(child_node, node:parent(), n_info, c_info)
    end
end

local function get_cpp_header_info(bufnr, lang)
    local parser = parsers.get_parser(bufnr, lang)
    local root = parser:parse()[1]:root()
    local namespace_info = {}
    local class_info = {}
    traverse_node(root, root, namespace_info, class_info)
    
    return namespace_info, class_info
end

local function get_selelct_lines(buf)
    local s_b, s_e = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]
    if s_b > s_e then
        local tem = s_e
        s_e = s_b
        s_b = tem
    end
    local select_lines = vim.api.nvim_buf_get_lines(buf, s_b - 1, s_e, null)
    return {s_b, s_e, s_e - s_b + 1, select_lines}
end

local function create_func_def()
    local file_name = vim.fn.bufname('%')
    local extend_name
    file_name = file_name:gsub([[\]], '/')
    file_name = file_name:gsub('^%./', '')
    extend_name = file_name
    file_name = file_name:match("(.+)%..+") or file_name
    extend_name = extend_name:match("(%.%w+)")
    local file_type = vim.bo.filetype

    if file_type == 'cpp' and (extend_name == '.hpp' or extend_name == '.h') then
        local n_info, c_info = get_cpp_header_info(0, file_type) 
        local select_lines = get_selelct_lines(0)
        local funcs = {}


        for _, str in ipairs(select_lines[4]) do
            local namespace = ""
            local class = ""
            local func = ""
            local pattern1 = "^%s*[%w_:]+%s+[%w_:]+%s*%([^()]*%)[^{};]*%s*;$"
            local pattern2 = "%s*[%w_:~]*%s*%([^()]*%)[^{};]*%s*;$"
            
            if str:match(pattern1) then
                local ret_type, rest = str:match("(%S+)%s+((%S+)%s*%(%s*(.*)%s*%)%s*%w*);")
                local line = _ + select_lines[1] - 1
                for index, value in ipairs(c_info) do
                    if line > value[2] and line < value[3] then
                        local tem = value[1]
                        class = tem .. "::" .. class
                    end
                end
                for index, value in ipairs(n_info) do
                    if line > value[2] and line < value[3] then
                        local tem = value[1]
                        tem = tem:gsub("^%s*", "")
                        if namespace == "" then
                            namespace = tem .. "::"
                        else
                            namespace = namespace .. tem .."::"
                        end
                        namespace = namespace:gsub("^%s*", "")
                    end
                end
                local n_c = namespace..class:gsub("^%s*", "")
                func = ret_type .. " " .. n_c .. rest .. "\n{\n\n\n}\n"
                table.insert(funcs, func)

            elseif str:match(pattern2) then
                local line = _ + select_lines[1] - 1
                for index, value in ipairs(c_info) do
                    if line > value[2] and line < value[3] then
                        local tem = value[1]
                        class = tem .. "::" .. class
                    end
                end
                func = class..str:match("^%s*(.-)%s*;?$").."\n{\n\n\n}\n"
                for index, value in ipairs(n_info) do
                    if line > value[2] and line < value[3] then
                        local tem = value[1]
                        tem = tem:gsub("^%s*", "")
                        if namespace == "" then
                            namespace = tem .. "::"
                        else
                            namespace = namespace .. tem .. "::"
                        end
                        namespace = namespace:gsub("^%s*", "")
                    end
                end
                func = namespace..func:match("^%s*(.-)$")
                table.insert(funcs, func)
            end
        end
        if utils.hasfile(current_dir..file_name..".cpp") then
            local file = io.open(current_dir..file_name..".cpp", "a+")
            if not file then
                vim.notify([[can't create func imp!]], "error", {
                    title = "error"
                })
                return
            end
            for _, v in ipairs(funcs) do
                file:write(v)
            end
            io.close(file)
            vim.notify("in "..current_dir..file_name..".cpp", "info", {
                title = "Create func imp!",
            })
        elseif utils.hasfile(current_dir..file_name..".c") then
            local file = io.open(current_dir..file_name..".c", "a+")
            if not file then
                vim.notify([[can't create func imp!]], "error", {
                    title = "error"
                })
                return
            end
            for _, v in ipairs(funcs) do
                file:write(v)
            end
            io.close(file)
            vim.notify("in "..current_dir..file_name..".c", "info", {
                title = "Create func imp!",
            })
        else
            local file = io.open(current_dir..file_name..".cpp", "a+")
            file:write([[#include "]]..file_name..extend_name..[["]].."\n\n\n\n")
            if not file then
                vim.notify([[can't create func imp!]], "error", {
                    title = "error"
                })
                return
            end
            for _, v in ipairs(funcs) do
                file:write(v)
            end
            io.close(file)
            vim.notify("in "..current_dir..file_name..".cpp", "info", {
                title = "Create imp!",
            })
        end
    else
        utils.clear_cmd()
    end
    
end

local mode
local buf 

local get_select_lines = function(buf)
    -- local lines_begin, lines_end = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]
    local lines_begin, lines_end = vim.fn.getcurpos()[2], vim.fn.line("v")

    local lines_num
    if(lines_begin > lines_end) then
        local tem = lines_end
        lines_end = lines_begin
        lines_begin = tem
    end
    lines_num = lines_end - lines_begin + 1
    local lines_str = vim.api.nvim_buf_get_lines(buf, lines_begin - 1, lines_end, null) 

    return {lines_begin, lines_end, lines_str, lines_num}
end

local up_lines = function()
    mode = vim.fn.mode()
    buf = vim.api.nvim_get_current_buf()
    local lines_info = get_select_lines(buf)

    local ifmove = lines_info[1] - 1
    if ifmove <= 0 then
        vim.notify("can't move!", "error",{
            title = "Error"
        })
        return
    end
    for i, line in ipairs(lines_info[3]) do
        local insert_pos = lines_info[1] - 2 + i - 1
        vim.api.nvim_buf_set_lines(buf, insert_pos, insert_pos, false, {line})
        vim.api.nvim_buf_set_lines(buf, lines_info[1] + i - 1, lines_info[1] + i, false, {})
    end

    vim.api.nvim_win_set_cursor(0, {lines_info[1] - 1, 1})
    vim.api.nvim_input("<ESC>")
    vim.api.nvim_input('V')
    for i = 1, lines_info[4] - 1, 1 do
        vim.api.nvim_input('j')
    end
    -- vim.api.nvim_win_set_cursor(0, {lines_info[2] - 1, 1})
end

local down_lines = function()
    mode = vim.fn.mode()
    buf = vim.api.nvim_get_current_buf()
    local lines_info = get_select_lines(buf)

    local ifmove = lines_info[2] + 1

    if ifmove > vim.fn.line('$') then
        return
    end

    for i = lines_info[2], lines_info[1], -1 do
        local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, null)[1]
        vim.api.nvim_buf_set_lines(buf, i + 1, i + 1, false, {line})
        vim.api.nvim_buf_set_lines(buf, i - 1, i, false, {})
    end
    vim.api.nvim_win_set_cursor(0, {lines_info[1] + 1, 1})
    vim.api.nvim_input("<ESC>")
    vim.api.nvim_input('V')
    for i = 1, lines_info[4] - 1, 1 do
        vim.api.nvim_input('j')
    end
    -- vim.api.nvim_win_set_cursor(0, {lines_info[2] + 1, 1})
end

local function move_lines(direction)
    if direction == "up" then
        up_lines()
    elseif direction == "down" then
        down_lines()
    end
end

return{
    create_file = create_file,
    create_func_def = create_func_def,
    move_lines = move_lines,
}

