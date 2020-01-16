GUI = {}
GUI.C = {}
GUI.C.resourceName = "OOPGUI"
GUI.C.assets = ":" .. GUI.C.resourceName .. "/assets/"

local colors = fileOpen(GUI.C.assets .. "colors.json")
color = fromJSON(fileRead(colors, fileGetSize(colors)))
fileClose(colors)
colors = nil

GUI.C.defaultColors = {
  background = color.dark,
  text = color.white,
  placeholder = color.gray,
  primary = color.flat.red,
  inactive = color.gray,
}

GUI.C.defaultFont = {name = "Quicksand-Regular", size = 18}
GUI.C.defaultMargin = 8
GUI.C.defaultScrollWidth = 16
GUI.C.scrollSpeed = 0.1