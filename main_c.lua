function initGUI()
  local config = fileOpen("config.lua")
  local gui = fileOpen("gui.lua")
  local data = fileRead(config, fileGetSize(config)) .. "\n" .. fileRead(gui, fileGetSize(gui))
  fileClose(config)
  fileClose(gui)
  return data
end