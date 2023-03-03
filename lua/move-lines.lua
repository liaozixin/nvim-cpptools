local buf 
local mode

local get_select_lines = function(buf)
    local lines_begin, lines_end = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]

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
    vim.api.nvim_command('normal! V')
    vim.api.nvim_win_set_cursor(0, {lines_info[2] - 1, 1})
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
    vim.api.nvim_command('normal! V')
    vim.api.nvim_win_set_cursor(0, {lines_info[2] + 1, 1})
end

return{
    up_lines = up_lines,
    down_lines = down_lines,
}

