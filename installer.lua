--- Simple program to be used as an installer script. Copy to repos and insert what is needed.

local to_get = {
  "L:lib/file_helper.lua:file_helper.lua",
  "extern:helper.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/helper.lua",
  "extern:lib/PrimeUI_cherrypicked.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/PrimeUI_cherrypicked.lua",
  "extern:lib/fzy_lua.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/fzy_lua.lua",
  "extern:lib/graph/init.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/graph/init.lua",
  "extern:lib/graph/node.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/graph/node.lua",
  "extern:lib/graph/shallow_serialize.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/graph/shallow_serialize.lua",
  "extern:lib/recipe_handler.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/recipe_handler.lua",
  "extern:lib/util.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/util.lua",
  "extern:lib/data_fixer_upper.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/lib/data_fixer_upper.lua",
  "extern:ui/crafting_menu.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/crafting_menu.lua",
  "extern:ui/items/add.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/add.lua",
  "extern:ui/items/common.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/common.lua",
  "extern:ui/items/edit.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/edit.lua",
  "extern:ui/items/edit_preferences.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/edit_preferences.lua",
  "extern:ui/items/get_item_details.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/get_item_details.lua",
  "extern:ui/items/menu.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/menu.lua",
  "extern:ui/items/remove.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/remove.lua",
  "extern:ui/items/view.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/items/view.lua",
  "extern:ui/machines/add.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/machines/add.lua",
  "extern:ui/machines/common.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/machines/common.lua",
  "extern:ui/machines/edit.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/machines/edit.lua",
  "extern:ui/machines/get_machine_details.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/machines/get_machine_details.lua",
  "extern:ui/machines/menu.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/machines/menu.lua",
  "extern:ui/machines/remove.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/machines/remove.lua",
  "extern:ui/machines/view.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/machines/view.lua",
  "extern:ui/main_menu.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/main_menu.lua",
  "extern:ui/quick_sub_menu.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/quick_sub_menu.lua",
  "extern:ui/util/catch_error.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/util/catch_error.lua",
  "extern:ui/util/confirmation_menu.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/util/confirmation_menu.lua",
  "extern:ui/util/get_integer.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/util/get_integer.lua",
  "extern:ui/util/get_text.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/util/get_text.lua",
  "extern:ui/util/good_response.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/util/good_response.lua",
  "extern:ui/util/search.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/util/search.lua",
  "extern:ui/title.lua:https://raw.githubusercontent.com/Fatboychummy-CC/Microcraft-Helper/main/ui/title.lua",
  --[[
  "extern:filename.lua:https://url.url/", -- if you need an external url
  "paste:filename.lua:pastecode", -- to download from pastebin
  "L:filename.lua:filename_on_repo.lua", -- Shorthand to download from the Fatboychummy-CC/Libraries repository.
  "E:filename.lua:filename_on_repo.lua" -- Shorthand to download from the Fatboychummy-CC/etc-programs repository.
  ]]
}
local program_name = "Microcraft Helper"
local pinestore_id = 56 -- Set this to the ID of the pinestore project if you wish to note to pinestore that a download has occurred.

-- #########################################

local RAW_URL_LIBRARIES = "https://raw.githubusercontent.com/Fatboychummy-CC/Libraries/main/"
local RAW_URL_PROGRAMS = "https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/"
local PASTE_URL = "https://pastebin.com/raw/"
local PINESTORE_ROOT = "https://pinestore.cc/"
local PINESTORE_PROJECT_ENDPOINT = PINESTORE_ROOT .. "api/project/"
local PINESTORE_DOWNLOAD_ENDPOINT = PINESTORE_ROOT .. "api/log/download"
local p_dir = ... or shell.dir()

local function print_warning(...)
  term.setTextColor(colors.orange)
  print(...)
  term.setTextColor(colors.white)
end

local function parse_pinestore_response(data)
  local success, response = pcall(textutils.unserializeJSON, data)
  if not success or not response then
    print_warning("Failed to parse response from pinestore.")
    return false
  end

  if response and not response.success then
    print_warning("Failed to get information from pinestore.")
    print_warning(response.error)
    return false
  end

  return response
end

local function download_file(url, filename)
  print("Downloading", filename)
  local h_handle, err = http.get(url) --[[@as Response]]
  if h_handle then
    local data = h_handle.readAll()
    h_handle.close()

    local f_handle, err2 = fs.open(fs.combine(p_dir, filename), 'w') --[[@as WriteHandle]]
    if f_handle then
      f_handle.write(data)
      f_handle.close()
      print("Done.")
      return
    end
    printError(url)
    error(("Failed to write file: %s"):format(err2), 0)
  end
  printError(url)
  error(("Failed to connect: %s"):format(err), 0)
end

local function get(...)
  local remotes = table.pack(...)

  for i = 1, remotes.n do
    local remote = remotes[i]

    local extern_file, extern_url = remote:match("^extern:(.-):(.+)$")
    local paste_file, paste = remote:match("^paste:(.-):(.+)$")
    local local_file, remote_file = remote:match("^L:(.-):(.+)$")
    local use_libraries = true

    if not local_file then
      local_file, remote_file = remote:match("^E:(.-):(.+)$")
      use_libraries = false
    end

    if extern_file then
      -- downlaod from external location
      download_file(extern_url, extern_file)
    elseif paste_file then
      -- download from pastebin
      local cb = ("%x"):format(math.random(0, 1000000))
      download_file(PASTE_URL .. textutils.urlEncode(paste) .. "?cb=" .. cb, paste_file)
    elseif local_file then
      -- download from main repository.
      if use_libraries then
        download_file(RAW_URL_LIBRARIES .. remote_file, local_file)
      else
        download_file(RAW_URL_PROGRAMS .. remote_file, local_file)
      end
    else
      error(("Could not determine information for '%s'"):format(remote), 0)
    end
  end
end

-- Installation is from the installer's directory.
if p_dir:match("^rom") then
  error("Attempting to install to the ROM. Please rerun but add arguments for install location (or run the installer script in the folder you wish to install to).", 0)
end

print(("You are about to install %s."):format(program_name))

-- Get the short description of the project from pinestore (if it exists).
if pinestore_id then
  local handle = http.get(PINESTORE_PROJECT_ENDPOINT .. tostring(pinestore_id))
  if handle then
    local data = parse_pinestore_response(handle.readAll())
    handle.close()

    if data then
      if type(data) == "table" and data.project and data.project.description_short then
        term.setTextColor(colors.white)
        write("Description from ")
        term.setTextColor(colors.green)
        write("PineStore")
        term.setTextColor(colors.white)
        print(":")
        print(data.project.description_short .. '\n')
      end
    end
  else
    print_warning("Failed to connect to pinestore.")
  end
end

write(("Going to install to:\n  /%s\n\nIs this where you want it to be installed? (y/n): "):format(fs.combine(p_dir, "/*")))

local key
repeat
  local _, _key = os.pullEvent("key")
  key = _key
until key == keys.y or key == keys.n

if key == keys.y then
  print("y")
  sleep()
  print(("Installing %s."):format(program_name))
  get(table.unpack(to_get))

  if type(pinestore_id) == "number" then
    local handle, err = http.post(
      PINESTORE_DOWNLOAD_ENDPOINT,
        textutils.serializeJSON({
          projectId = pinestore_id,
        })
    )
    if handle then
      parse_pinestore_response(handle.readAll())
      handle.close()
    else
      print_warning("Failed to connect to pinestore.")
    end
  end
else
  print("n")
  sleep()
  error("Installation cancelled.", 0)
end