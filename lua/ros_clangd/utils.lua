local M = {}

-- check if file exists by opening it
function M.file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true
  else return false end
end

function M.get_current_package_name(path)
    path = path or vim.fn.expand("%:p")
    -- use rospkg to get package name
    local pkg_name = vim.fn.system('python3 -c "import rospkg; print(rospkg.get_package_name(\''..path..'\'))' )

    print(pkg_name)
    -- clean up output
    pkg_name, _ = string.gsub(pkg_name, "\r", "")
    pkg_name, _ = string.gsub(pkg_name, "\n", "")
    if pkg_name == "None" then
        return
    end
    return pkg_name
end

function M.go_to_buffer_id(bufnr)
  local winnr = vim.fn.bufwinnr(bufnr)
  local winid = vim.fn.win_getid(winnr)
  vim.fn.win_gotoid(winid)
end

function M.open_split()
    vim.cmd("split")
    -- M.resize_split()
end

function M.open_terminal()
  M.open_split()
  vim.cmd("terminal")
end

function M.build(path, cmd)
  local current_bufnr = vim.fn.bufnr()
  local bufnr = vim.fn.bufnr("catkin build")
    if bufnr ~= -1 then
      M.go_to_buffer_id(bufnr)
    else
      M.open_terminal()
    end
end

function M.global_db(ws_path)
  -- remove white spaces. might be unnecessary
  local ws_build_dir_path = string.gsub(ws_path, '%s+', '') .. '/build/'
  -- clangd doesn't accept '~/' in the path, wants it full
  ws_build_dir_path = string.gsub(ws_build_dir_path, '~', '$HOME')

  if not M.file_exists(ws_build_dir_path .. 'compile_commands.json') then
    vim.ui.input( {prompt='no database. want to build the global? [Y/n] '},
    function (input)
      if input == 'n' then
        print('not building the database')
        return
      else
        local build_cmd = 'cd \'' .. ws_path .. '\' && catkin_build'
        M.build(ws_path, build_cmd)
        return "--compile-commands-dir=".. ws_build_dir_path
      end
    end)
  end

end

function M.local_db(ws_path,path)
  local name = M.get_current_package_name(path)

  local build_dir_loc = ws_path .. '/build/' .. name
  if not M.file_exists(build_dir_loc .. '/compile_commands.json') then
    vim.ui.input({prompt='no database. want to build the local? [Y/n] '},
    function (input)
      if input == 'n' then
        print('not building the database')
        return
      else
        -- local build_cmd = 'cd \'' .. ws_dir_path .. '\' && catkin build -DCMAKE_COMPILE_COMMANDS=ON \'' .. name .. '\''
        -- build(ws_dir_path, build_cmd)
        return "--compile-commands-dir=".. build_dir_loc
      end
    end)
  end
end

function M.verify_jsons(path)

  -- redirect error so that the returned string is empty in such case
  local ws_dir_path = vim.fn.system('catkin locate --workspace \'' .. path .. '\' 2>/dev/null')
  -- print(ws_dir_path)

  -- if path is empty then there is no ros on system or path is not
  -- a package
  if ws_dir_path == nil or ws_dir_path == '' then
    print(" not in a ros package")
    return
  end

  if CONFIG.ws_json == true then
    -- this function could return nil
    return M.global_db(ws_dir_path)

  -- else if looking for single package json
  elseif CONFIG.ws_json == false then
    return M.local_db(ws_dir_path)
  end

end

return M
