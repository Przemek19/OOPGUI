GUI.elements = {}
GUI.data = {}
GUI.data.lastID = 0
GUI.data.isRendering = false

sw, sh = guiGetScreenSize()

GUI.createElement = function(t, args) 
  GUI.data.lastID = GUI.data.lastID + 1
  local ID = tonumber(GUI.data.lastID)
  local e = {}
  e = (type(args) == "table") and args or {}
  if not GUI.data.isRendering then addEventHandler("onClientRender", root, GUI.render) end
  GUI.data.isRendering = true
  e.id = ID
  e.type = t
  e.position = e.position or {x = 0, y = 0}
  e.size = e.size or {width = 0, height = 0}
  e.color = e.color or {}
  e.font = e.font or {}
  e.visible = true
  for i, v in pairs(GUI.C.defaultColors) do
    if not e.color[i] then
      e.color[i] = v
    end
  end
  e.insertChild = function(self, ...)
    for i, child in pairs(arg) do
      if GUI.isElement(child) then
        child.parent = self
      end  
    end
  end
  e.getChildren = function(self)
    local elements = {}
    for i, v in pairs(GUI.elements) do
      if v.parent == self then
        table.insert(elements, v)
      end
    end
    return elements
  end
  e.destroy = function(self)
    for i, v in pairs(self:getChildren()) do
      GUI.elements[v.id] = nil
    end
    GUI.elements[self.id] = nil
    if #GUI.elements == 0 then removeEventHandler("onClientRender", root, GUI.render) GUI.data.render = false end
  end

  if t == "editbox" then
    e.currentCharIndex = 0
  elseif t == "text" then
    e.textWidth = dxGetTextWidth((e.text or ""), 1, GUI.font(e.font))
  end

  GUI.elements[ID] = e
  return GUI.elements[ID]
end

GUI.tocolor = function(color)
  return tocolor((color[1] or 0), (color[2] or 0), (color[3] or 0), (color[4] or 255))
end

GUI.changeColor = function(color, r, g, b, a)
  r = r or 0
  g = g or 0
  b = b or 0
  a = a or 0
  local newColor = {}
  if not color[4] then color[4] = 255 end
  newColor[1] = math.min(math.max(0, color[1] + r), 255)
  newColor[2] = math.min(math.max(0, color[2] + g), 255)
  newColor[3] = math.min(math.max(0, color[3] + b), 255)
  newColor[4] = math.min(math.max(0, color[4] + a), 255)
  return newColor
end

GUI.createCorner = function(px)
  local texture = dxCreateTexture(px, px)
  local pixels = dxGetTexturePixels(texture)
  for x = 0, px - 1 do
    for y = 0, px - 1 do
      if math.sqrt(((px - x)^2 + (px - y)^2)) < px then
        dxSetPixelColor(pixels, x, y, 255, 255, 255, 255)
      end
    end
  end
  dxSetTexturePixels(texture, pixels)
  return texture
end

GUI.tex = {}
GUI.tex.corner = GUI.createCorner(256)

GUI.data.fonts = {}
GUI.font = function(font)
  if not font then font = GUI.C.defaultFont end
  font.name = font.name or GUI.C.defaultFont.name
  font.size = font.size or GUI.C.defaultFont.size
  if not GUI.data.fonts[font.name] then GUI.data.fonts[font.name] = {} end
  if (fileExists(GUI.C.assets .. "fonts/" .. font.name .. ".ttf")) then
    if not GUI.data.fonts[font.name][font.size] then GUI.data.fonts[font.name][font.size] = dxCreateFont(GUI.C.assets .. "fonts/" .. font.name .. ".ttf", font.size, false, "default") end
  else
    return "Arial"
  end
  return GUI.data.fonts[font.name][font.size]
end

GUI.drawCorneredRectangle = function(x, y, width, height, br, color, postGUI)
  br = math.min(br, math.min(width / 2, height / 2))
  dxDrawRectangle(x + br, y + br, width - br * 2, height - br * 2, color, postGUI)

  dxDrawImage(x, y, br, br, GUI.tex.corner, 0, 0, 0, color, postGUI) -- TOP LEFT
  dxDrawImage(x, y + height - br, br, br, GUI.tex.corner, 270, 0, 0, color, postGUI) -- BOTTOM LEFT
  dxDrawImage(x + width - br, y, br, br, GUI.tex.corner, 90, 0, 0, color, postGUI) -- TOP RIGHT
  dxDrawImage(x + width - br, y + height - br, br, br, GUI.tex.corner, 180, 0, 0, color, postGUI) -- BOTTOM RIGHT

  dxDrawRectangle(x + br, y, width - br * 2, br, color, postGUI) -- TOP
  dxDrawRectangle(x + br, y + height - br, width - br * 2, br, color, postGUI) -- BOTTOM
  dxDrawRectangle(x, y + br, br, height - br * 2, color, postGUI) -- LEFT
  dxDrawRectangle(x + width - br, y + br, br, height - br * 2, color, postGUI) -- RIGHT
end

GUI.drawText = function(text, x, y, width, height, color, font, alignX, alignY, wordBreak, colorCoded, postGUI)
  if alignX == "center" then
    x = x * 2
  elseif alignX == "right" then
    width = x + width
  else
    width = width + x
  end

  if alignY == "center" then
    y = y * 2
  elseif alignY == "bottom" then
    height = y + height
  else

  end

  dxDrawText((text or ""), x, y, width, height, color, 1, font, alignX, alignY, false, wordBreak, postGUI, colorCoded)
end

GUI.isCursorInPosition = function(x, y, width, height)
  local cx, cy = getCursorPosition()
  cx, cy = (cx or 0) * sw, (cy or 0) * sh
  return (cx >= x) and (cy >= y) and (cx <= x + width) and (cy <= y + height)
end

GUI.repeatChar = function(char, num)
  local str = ""
  for i = 1, num do
    str = str .. char
  end
  return str
end

GUI.draw = dxCreateRenderTarget(sw, sh, true)

GUI.resize = function(size)
  for i, element in pairs(GUI.elements) do
    element.position = {x = math.floor(element.position.x * size), y = math.floor(element.position.y * size)}
    element.size = {width = math.floor(element.size.width or element.size.height * 2) * size, height = math.floor(element.size.height or element.size.width / 2) * size}
    if element.font.size then
      element.font.size = math.floor(element.font.size * size)
    end
  end
end

local renderProgress = 0
GUI.render = function()
  renderProgress = renderProgress == 1 and 0 or 1
  if GUI.renderTarget == true then dxSetRenderTarget(GUI.draw) end
  for id, element in pairs(GUI.elements) do
    if element.parent then element.visible = element.parent.visible end
    if element.visible then
      if element.renderTarget then
        if not element.texture then element.texture = dxCreateRenderTarget(sw, sh, true) end
        dxSetRenderTarget(element.texture)
      end
      if element.parent and element.parent.scrollRT then
        if (element.parent.lastRenderProgress and element.parent.lastRenderProgress ~= renderProgress) then
          dxSetRenderTarget(element.parent.scrollRT, true)
        else
          dxSetRenderTarget(element.parent.scrollRT)
        end
        element.parent.lastRenderProgress = renderProgress
      end
      if element.type == "rectangle" then
        if element.borderRadius then
          GUI.drawCorneredRectangle(element.position.x, element.position.y, element.size.width, element.size.height, element.borderRadius, GUI.tocolor(element.color.background), element.postGUI)
        else
          dxDrawRectangle(element.position.x, element.position.y, element.size.width, element.size.height, GUI.tocolor(element.color.background), element.postGUI)
        end
      elseif element.type == "button" then
        local c = GUI.tocolor(element.color.primary)
        local realX, realY
        if element.sPos and element.sPos.x and element.sPos.y then
          realX, realY = element.sPos.x, element.sPos.y
        else
          realX, realY = element.position.x, element.position.y
        end
        if GUI.isCursorInPosition(realX, realY, element.size.width, element.size.height) or (element.enterClick and getKeyState("enter")) then
          if getKeyState("mouse1") or getKeyState("mouse2") or (element.enterClick and getKeyState("enter")) then
            c = GUI.tocolor(element.color.focus or GUI.changeColor(element.color.primary, -32, -32, -32))
          else
            c = GUI.tocolor(element.color.hover or GUI.changeColor(element.color.primary, -16, -16, -16))
          end
        end
        if element.borderRadius then
          GUI.drawCorneredRectangle(element.position.x, element.position.y, element.size.width, element.size.height, element.borderRadius, c, element.postGUI)
        else
          dxDrawRectangle(element.position.x, element.position.y, element.size.width, element.size.height, c, element.postGUI)
        end
        GUI.drawText(element.text, element.position.x, element.position.y, element.size.width, element.size.height, GUI.tocolor(element.color.text), GUI.font(element.font.size and element.font or {name = (element.font.name or GUI.C.defaultFont.name), size = math.min(element.size.width, element.size.height) / 2.5}), (element.alignX or "center"), (element.alignY or "center"), true, false, element.postGUI)
      elseif element.type == "text" then
        if GUI.devmode then dxDrawRectangle(element.position.x, element.position.y, element.size.width, element.size.height, tocolor(255, 255, 255, 40)) end
        element.textWidth = dxGetTextWidth((element.text or ""), 1, GUI.font(element.font))
        GUI.drawText(element.text, element.position.x, element.position.y, element.size.width, element.size.height, GUI.tocolor(element.color.text), GUI.font(element.font), (element.alignX or "left"), (element.alignY or "top"), element.wordBreak, element.colorCoded, element.postGUI)
      elseif element.type == "editbox" then
        if not element.text then element.text = "" end
        if element.borderRadius then
          GUI.drawCorneredRectangle(element.position.x, element.position.y, element.size.width, element.size.height, element.borderRadius, GUI.tocolor(element.color.background), element.postGUI)
        else
          dxDrawRectangle(element.position.x, element.position.y, element.size.width, element.size.height, GUI.tocolor(element.color.background), element.postGUI)
        end
        local m = element.margin or GUI.C.defaultMargin
        local text = not element.masked and (element.text or "") or GUI.repeatChar("*", utf8.len(element.text or ""))
        local f = GUI.font(element.font.size and element.font or {name = (element.font.name or GUI.C.defaultFont.name), size = math.min(element.size.width, element.size.height) / 2.5})
        GUI.drawText(text, element.position.x + m, element.position.y + m, element.size.width - 2 * m, element.size.height - 2 * m, GUI.tocolor(element.color.text), f, "left", "center", false, element.colorCoded, element.postGUI)
        if utf8.len(text) == 0 and element.placeholder then
          GUI.drawText(element.placeholder, element.position.x + m, element.position.y + m, element.size.width - 2 * m, element.size.height - 2 * m, GUI.tocolor(element.color.placeholder), f, "left", "center", false, element.colorCoded, element.postGUI)
        end
        if element.active then
          local sin = (((math.sin(getTickCount() / 200)) / 2 + 0.5))
          local c = GUI.tocolor({element.color.text[1], element.color.text[2], element.color.text[3], (element.color.text[4] or 255) * sin})
          dxDrawRectangle(element.position.x + m + dxGetTextWidth(utf8.sub(text, 1, element.currentCharIndex), 1, f, element.colorCoded), element.position.y + m, 1, element.size.height - 2 * m, c, element.postGUI)
        end
      elseif element.type == "checkbox" then
        local x, y, w, h = element.position.x, element.position.y, (element.size.width or element.size.height * 2), (element.size.height or element.size.width / 2)
        element.size.width = w
        element.size.height = h
        local m = element.margin or GUI.C.defaultMargin
        local f = GUI.font(element.font.size and element.font or {name = (element.font.name or GUI.C.defaultFont.name), size = h / 2.75})
        if element.borderRadius then
          GUI.drawCorneredRectangle(x, y, w, h, element.borderRadius, GUI.tocolor(element.color.background), element.postGUI)
        else
          dxDrawRectangle(x, y, w, h, GUI.tocolor(element.color.background), element.postGUI)
        end

        if element.state then
          if element.borderRadius then
            GUI.drawCorneredRectangle(x + h + m, y + m, h - m * 2, h - m * 2, element.borderRadius, GUI.tocolor(element.color.primary), element.postGUI)
          else
            dxDrawRectangle(x + h + m, y + m, h - m * 2, h - m * 2, GUI.tocolor(element.color.primary), element.postGUI)
          end
          GUI.drawText("ON", x, y, h + m, h, GUI.tocolor(element.color.primary), f, "center", "center", nil, nil, element.postGUI)     
        else
          if element.borderRadius then
            GUI.drawCorneredRectangle(x + m, y + m, h - m * 2, h - m * 2, element.borderRadius, GUI.tocolor(element.color.inactive), element.postGUI)
          else
            dxDrawRectangle(x + m, y + m, h - m * 2, h - m * 2, GUI.tocolor(element.color.inactive), element.postGUI)
          end
          GUI.drawText("OFF", x + h - m, y, h + m, h, GUI.tocolor(element.color.inactive), f, "center", "center", nil, nil, element.postGUI)
        end
      elseif element.type == "scroll" then
        local ch = element:getChildren()
        local scrollHeight = 0
        local scrollProgress = element.scrollProgress or 0
        element.scrollProgress = scrollProgress
        local biggestElementHeight = 0
        for i, v in pairs(ch) do
          if not v.scrollPositionY then
            v.scrollPositionY = v.position.y
          end
          if not v.sPos then v.sPos = {} end
          if v.scrollPositionY + v.size.height > scrollHeight then
            scrollHeight = v.scrollPositionY + v.size.height
            biggestElementHeight = v.size.height
          end    
        end
        for i, v in pairs(ch) do
          v.sPos.x = element.position.x + v.position.x
          v.sPos.y = element.position.y + v.scrollPositionY - (math.max(scrollHeight - element.size.height, 0) * scrollProgress) -- TODO
          v.position.y = v.scrollPositionY - (math.max(scrollHeight - element.size.height, 0) * scrollProgress)
        end
        
        if not element.scrollRT then
          element.scrollRT = dxCreateRenderTarget(element.size.width, element.size.height, true)

          
        end
        dxDrawImage(element.position.x, element.position.y, element.size.width, element.size.height, element.scrollRT, _, _, _, _, element.postGUI)

        local scrlH = math.max(scrollHeight, 0)
        local sH = math.min(element.size.height * element.size.height / scrlH, element.size.height)
        local fL = element.size.height - sH / 1
        local sY = element.position.y + (fL * scrollProgress)
        element.scrollHeight = scrlH

        local x1 = element.position.x + element.size.width - (element.scrollWidth or GUI.C.defaultScrollWidth)
        local y1 = element.position.y
        local width1 = (element.scrollWidth or GUI.C.defaultScrollWidth)
        local height1 = element.size.height
        local x2 = element.position.x + element.size.width - (element.scrollWidth or GUI.C.defaultScrollWidth)
        local y2 = element.position.y + ((element.size.height - math.min(element.size.height * element.size.height / scrlH, element.size.height) / 1) * element.scrollProgress)
        local width2 = (element.scrollWidth or GUI.C.defaultScrollWidth)
        local height2 = math.min(element.size.height * element.size.height / scrlH, element.size.height)

        local sColor = GUI.tocolor(element.color.primary)
        if GUI.isCursorInPosition(x2, y2, width2, height2) then
          sColor = GUI.tocolor(element.color.hover or GUI.changeColor(element.color.primary, -8, -8, -8))
        end

        local y3 = y1 + height2 / 2
        local height3 = height1 - height2

        if element.scrollActive then
          local _, cy = getCursorPosition()
          cy = cy * sh
          if math.min(math.max(cy - y3, 0), height3) / height3 == math.min(math.max(cy - y3, 0), height3) / height3 then
            element.scrollProgress = math.min(math.max(cy - y3, 0), height3) / height3
          end
          sColor = GUI.tocolor(element.color.focus or GUI.changeColor(element.color.primary, -16, -16, -16))
        end

        GUI.drawCorneredRectangle(element.position.x + element.size.width - (element.scrollWidth or GUI.C.defaultScrollWidth), element.position.y, (element.scrollWidth or GUI.C.defaultScrollWidth), element.size.height, (element.borderRadius or 0), GUI.tocolor(element.color.background), element.postGUI)
        GUI.drawCorneredRectangle(element.position.x + element.size.width - (element.scrollWidth or GUI.C.defaultScrollWidth), sY, (element.scrollWidth or GUI.C.defaultScrollWidth), sH, (element.borderRadius or 0), sColor, element.postGUI)
      
      elseif element.type == "image" then
        if element.image then
          dxDrawImage(element.position.x, element.position.y, element.size.width, element.size.height, element.image, (element.rotation or 0), 0, 0, (element.color.image and GUI.tocolor(element.color.image) or GUI.tocolor({255, 255, 255})), element.postGUI)
        end
      end
      if GUI.devmode then
        local parent = element.parent and element.parent.type .. ":" .. element.parent.id or nil
        local t = "[" .. element.type .. ":" .. element.id .. "]\nparent:[" .. tostring(parent) .. "]"
        local tW = dxGetTextWidth(t, 1, GUI.font({size = 10}))
        if not element.devmodeColor then
          local r, g, b = math.random(0, 255), math.random(0, 255), math.random(0, 255)
          element.devmodeColor = tocolor(r, g, b)
        end
        local realX, realY
        if element.sPos and element.sPos.x and element.sPos.y then
          realX, realY = element.sPos.x, element.sPos.y
        else
          realX, realY = element.position.x, element.position.y
        end
        if GUI.isCursorInPosition(realX, realY, element.size.width, element.size.height) then
          dxDrawRectangle(realX + element.size.width / 2 - tW / 2 - 10, realY + element.size.height / 2 - 20, tW + 20, 40, tocolor(0, 0, 0), true)
          GUI.drawText(t, realX, realY, element.size.width, element.size.height, element.devmodeColor, GUI.font({size = 10}), "center", "center", nil, nil, true)
        end
        dxDrawLine(realX, realY, realX + element.size.width, realY, element.devmodeColor, 1, true)
        dxDrawLine(realX, realY + element.size.height, realX + element.size.width, realY + element.size.height, element.devmodeColor, 1, true)
      
        dxDrawLine(realX, realY, realX, realY + element.size.height, element.devmodeColor, 1, true)
        dxDrawLine(realX + element.size.width, realY, realX + element.size.width, realY + element.size.height, element.devmodeColor, 1, true)
      
        if GUI.devmodeLine then
          dxDrawLine(sw / 2, 0, sw / 2, sh, tocolor(255, 255, 255, 190))
          dxDrawLine(0, sh / 2, sw, sh / 2, tocolor(255, 255, 255, 190))
          for i = 1, math.floor(sw / 2 / GUI.devmodeLine) do
            dxDrawLine(sw / 2 + i * GUI.devmodeLine, 0, sw / 2 + i * GUI.devmodeLine, sh, tocolor(i % 3 == 0 and 180 or 0, i % 3 == 1 and 180 or 0, i % 3 == 2 and 180 or 0, 6))
            dxDrawLine(sw / 2 - i * GUI.devmodeLine, 0, sw / 2 - i * GUI.devmodeLine, sh, tocolor(i % 3 == 0 and 180 or 0, i % 3 == 1 and 180 or 0, i % 3 == 2 and 180 or 0, 6))
          end
          for i = 1, math.floor(sw / 2 / GUI.devmodeLine) do
            dxDrawLine(0, sh / 2 + i * GUI.devmodeLine, sw, sh / 2 + i * GUI.devmodeLine, tocolor(i % 3 == 0 and 180 or 0, i % 3 == 1 and 180 or 0, i % 3 == 2 and 180 or 0, 6))
            dxDrawLine(0, sh / 2 - i * GUI.devmodeLine, sw, sh / 2 - i * GUI.devmodeLine, tocolor(i % 3 == 0 and 180 or 0, i % 3 == 1 and 180 or 0, i % 3 == 2 and 180 or 0, 6))
          end
        end
      end
      if element.renderTarget then
        dxSetRenderTarget()
      end
      if element.parent and element.parent.scrollRT then
        dxSetRenderTarget()
      end
    end
  end
  if GUI.renderTarget == true then dxSetRenderTarget() end
end

GUI.isElement = function(element)
  return type(element) == "table"
end

GUI.getActiveElement = function()
  for i = #GUI.elements, 1, -1 do
    if GUI.isElement(GUI.elements[i]) and GUI.elements[i].active then return GUI.elements[i] end
  end
  return false
end

addEventHandler("onClientClick", root, function(bttn, state, x, y)
  if not GUI.data.isRendering then return end
  for i = #GUI.elements, 1, -1 do
    if GUI.isElement(GUI.elements[i]) and GUI.elements[i].type == "scroll" then
      GUI.elements[i].scrollActive = nil
    end
  end
  if state ~= "down" then return end
  
  for i = #GUI.elements, 1, -1 do
    if GUI.isElement(GUI.elements[i]) then
      GUI.elements[i].active = nil
    end
  end

  guiSetInputMode("allow_binds")
  for i = #GUI.elements, 1, -1 do
    local element = GUI.elements[i]
    if GUI.isElement(element) then
      local realX, realY
      if element.sPos and element.sPos.x and element.sPos.y then
        realX, realY = element.sPos.x, element.sPos.y
      else
        realX, realY = element.position.x, element.position.y
      end
      if element.type == "scroll" and element.visible then
        local scrlH = element.scrollHeight or 0

        element.scrollHeight = scrlH


        local x1 = realX + element.size.width - (element.scrollWidth or GUI.C.defaultScrollWidth)
        local y1 = realY
        local width1 = (element.scrollWidth or GUI.C.defaultScrollWidth)
        local height1 = element.size.height
        local x2 = realX + element.size.width - (element.scrollWidth or GUI.C.defaultScrollWidth)
        local y2 = realY + ((element.size.height - math.min(element.size.height * element.size.height / scrlH, element.size.height) / 1) * element.scrollProgress)
        local width2 = (element.scrollWidth or GUI.C.defaultScrollWidth)
        local height2 = math.min(element.size.height * element.size.height / scrlH, element.size.height)
        if GUI.isCursorInPosition(x1, y1, width1, height1) then
          element.scrollActive = true
        end

      end
      if GUI.isCursorInPosition(realX, realY, element.size.width, element.size.height) and element.visible then
        if element.onclick and type(element.onclick) == "function" then
          element.onclick(bttn, state)
        end
        if element.type == "checkbox" then
          element.state = not element.state
          if type(element.onChangeState) == "function" then element.onChangeState(element.state) end
        elseif element.type == "editbox" then
          guiSetInputMode("no_binds")
          element.currentCharIndex = utf8.len(element.text)
        end
        element.active = true
        break
      end
    end
  end
end)

GUI.st = function(s)
  if type(s) == "string" then
    local tab = {}
    for i = 1, utf8.len(s) do
      tab[i] = utf8.sub(s, i, i)
    end
    return tab
  elseif type(s) == "table" then
    return table.concat(s)
  else
    return false   
  end
end

GUI.getElementsByType = function(type)
  local elements = {}
  for i = 1, #GUI.elements do
    if GUI.isElement(GUI.elements[i]) then
      if GUI.elements[i].type == type then
        table.insert(elements, GUI.elements[i])
      end
    end
  end
  return elements
end

local fastBackspaceSetTimer
local fastBackspaceTimer

addEventHandler("onClientKey", root, function(bttn, isPressed)
  if not GUI.data.isRendering then return end
  if not isPressed then
    if fastBackspaceSetTimer and isTimer(fastBackspaceSetTimer) then fastBackspaceSetTimer:destroy() fastBackspaceSetTimer = nil end
    if fastBackspaceTimer and isTimer(fastBackspaceTimer) then fastBackspaceTimer:destroy() fastBackspaceTimer = nil end
    return
  end

  if bttn == "enter" then
    for i = 1, #GUI.elements do
      local element = GUI.elements[i]
      if GUI.isElement(element) and element.enterClick and type(element.onclick) == "function" then
        element.onclick("enter", "down")
      end
    end
  end
  if bttn == "mouse_wheel_up" then
    for i, element in pairs(GUI.elements) do
      if element.type == "scroll" and GUI.isCursorInPosition(element.position.x, element.position.y, element.size.width, element.size.height) then
        local scrollSpeed = element.scrollSpeed or element.size.height / element.scrollHeight * GUI.C.scrollSpeed
        element.scrollProgress = (element.scrollProgress - scrollSpeed >= 0) and element.scrollProgress - scrollSpeed or 0
        break
      end
    end
  elseif bttn == "mouse_wheel_down" then
    for i, element in pairs(GUI.elements) do
      if element.type == "scroll" and GUI.isCursorInPosition(element.position.x, element.position.y, element.size.width, element.size.height) then
        local scrollSpeed = element.scrollSpeed or element.size.height / element.scrollHeight * GUI.C.scrollSpeed
        element.scrollProgress = (element.scrollProgress + scrollSpeed <= 1) and element.scrollProgress + scrollSpeed or 1
        break
      end
    end
  end

  local element = GUI.getActiveElement()
  if not element then return end
  if not element.visible then return end

  if bttn == "backspace" then
    if element.type ~= "editbox" then return end
    if fastBackspaceSetTimer and isTimer(fastBackspaceSetTimer) then fastBackspaceSetTimer:destroy() fastBackspaceSetTimer = nil end
    if fastBackspaceTimer and isTimer(fastBackspaceTimer) then fastBackspaceTimer:destroy() fastBackspaceTimer = nil end
    fastBackspaceSetTimer = setTimer(function()
      fastBackspaceTimer = setTimer(function()
        if getKeyState("backspace") then
          local tab = GUI.st(element.text)
          table.remove(tab, element.currentCharIndex)
          element.text = GUI.st(tab)
          element.currentCharIndex = element.currentCharIndex > 0 and element.currentCharIndex - 1 or 0
        else
          if fastBackspaceSetTimer and isTimer(fastBackspaceSetTimer) then fastBackspaceSetTimer:destroy() fastBackspaceSetTimer = nil end
          if fastBackspaceTimer and isTimer(fastBackspaceTimer) then fastBackspaceTimer:destroy() fastBackspaceTimer = nil end
        end
      end, 30, 0)
    end, 500, 1)
    local tab = GUI.st(element.text)
    table.remove(tab, element.currentCharIndex)
    element.text = GUI.st(tab)
    element.currentCharIndex = element.currentCharIndex > 0 and element.currentCharIndex - 1 or 0
  elseif bttn == "arrow_l" then
    element.currentCharIndex = element.currentCharIndex > 0 and element.currentCharIndex - 1 or 0
  elseif bttn == "arrow_r" then
    element.currentCharIndex = element.currentCharIndex < utf8.len(element.text) and element.currentCharIndex + 1 or utf8.len(element.text)
  elseif bttn == "tab" then
    local editboxes = GUI.getElementsByType("editbox")
    local isActiveGiven
    for i, editbox in pairs(editboxes) do
      if editboxes[i - 1] and editboxes[i - 1].active then
        editboxes[i - 1].active = false
        editboxes[i].active = true
        isActiveGiven = true
        break
      elseif #editboxes == i then
        editboxes[#editboxes].active = false
        editboxes[1].active = true
        isActiveGiven = true
        break
      end
    end
    if not isActiveGiven and #editboxes > 0 then
      editboxes[1].active = true
    end
  end
end)

addEventHandler("onClientCharacter", root, function(char)
  if not GUI.data.isRendering then return end
  local element = GUI.getActiveElement()
  if not element then return end
  if not element.visible then return end
  if element.type ~= "editbox" then return end
  local tab = GUI.st(element.text)
  element.currentCharIndex = element.currentCharIndex or utf8.len(element.text or "")
  for i = #tab, element.currentCharIndex + 1, -1 do
    tab[i + 1] = tab[i]
  end
  tab[element.currentCharIndex + 1] = char
  local f = GUI.font(element.font.size and element.font or {name = (element.font.name or GUI.C.defaultFont.name), size = math.min(element.size.width, element.size.height) / 2.5})
  if dxGetTextWidth(GUI.st(tab), 1, f) <= element.size.width - 2 * (element.margin or GUI.C.defaultMargin) then
    element.text = GUI.st(tab)
    element.currentCharIndex = element.currentCharIndex + 1
  end
end)

------------------- TEST --------------------

--GUI.devmode = true
--GUI.devmodeLine = 64

local margin = 16
local radius = 4
local row = sh / 2 - 256

local backWindow = GUI.createElement("rectangle")
backWindow.position = {x = sw / 2 - 512 - margin, y = sh / 2 - 256 - margin * 2 - 32}
backWindow.size = {width = 1024 + margin * 2, height = 512 + margin * 3 + 32}
backWindow.color.background = GUI.changeColor(color.dark, _, _, _, -100)
backWindow.borderRadius = radius

local window = GUI.createElement("rectangle")
window.position = {x = sw / 2 - 512, y = sh / 2 - 256}
window.size = {width = 1024, height = 512}
window.color.background = GUI.changeColor(color.dark, _, _, _, -128)
window.borderRadius = radius

local title = GUI.createElement("text", {text = "OOP GUI System by #c0392bPevo", font = {size = 32}})
title.position = {x = sw / 2 - 512 + margin, y = sh / 2 - 256 - margin - 32}
title.size = {width = 1024 - 2 * margin, height = 32}
title.colorCoded = true
title.alignX, title.alignY = "center", "center"

local editbox = GUI.createElement("editbox")
editbox.position = {x = sw / 2 - 512 + margin, y = row + margin}
editbox.size = {width = 512 - 2 * margin, height = 40}
editbox.placeholder = "Editbox..."
editbox.color.background = GUI.changeColor(color.dark, _, _, _, -64)
editbox.borderRadius = radius
row = row + margin + 40

local editbox2 = GUI.createElement("editbox")
editbox2.position = {x = sw / 2 - 512 + margin, y = row + margin}
editbox2.size = {width = 512 - 2 * margin, height = 40}
editbox2.placeholder = "Editbox..."
editbox2.color.background = GUI.changeColor(color.dark, _, _, _, -64)
editbox2.borderRadius = radius
row = row + margin + 40

local editbox3 = GUI.createElement("editbox")
editbox3.position = {x = sw / 2 - 512 + margin, y = row + margin}
editbox3.size = {width = 512 - 2 * margin, height = 40}
editbox3.placeholder = "Editbox..."
editbox3.color.background = GUI.changeColor(color.dark, _, _, _, -64)
editbox3.borderRadius = radius
row = row + margin + 40

local editbox4 = GUI.createElement("editbox")
editbox4.position = {x = sw / 2 - 512 + margin, y = row + margin}
editbox4.size = {width = 512 - 2 * margin, height = 40}
editbox4.placeholder = "Editbox..."
editbox4.color.background = GUI.changeColor(color.dark, _, _, _, -64)
editbox4.borderRadius = radius
row = row + margin + 40

local editbox5 = GUI.createElement("editbox")
editbox5.position = {x = sw / 2 - 512 + margin, y = row + margin}
editbox5.size = {width = 512 - 2 * margin, height = 40}
editbox5.placeholder = "Masked Editbox..."
editbox5.masked = true
editbox5.color.background = GUI.changeColor(color.dark, _, _, _, -64)
editbox5.borderRadius = radius
row = row + margin + 40



local checkbox = GUI.createElement("checkbox")
checkbox.position = {x = sw / 2 - 512 + margin, y = row + margin}
checkbox.size = {width = 64}
checkbox.borderRadius = radius

local checkbox2 = GUI.createElement("checkbox")
checkbox2.position = {x = sw / 2 - 512 + margin, y = row + margin + 32 + margin}
checkbox2.size = {width = 64}
checkbox2.borderRadius = radius

local checkbox3 = GUI.createElement("checkbox")
checkbox3.position = {x = sw / 2 - 512 + margin, y = row + margin + 64 + margin * 2}
checkbox3.size = {width = 64}
checkbox3.borderRadius = radius
checkbox3.state = true

local circleButton = GUI.createElement("button")
circleButton.text = "Circle Button"
circleButton.position = {x = sw / 2 - 512 + margin * 2 + 96, y = row + margin}
circleButton.size = {width = 128, height = 128}
circleButton.borderRadius = 256
circleButton.font.size = 16

local lightText = GUI.createElement("text")
lightText.position = {x = sw / 2 - 512 + margin * 2 + 64, y = row + margin}
lightText.size = {width = 512 - 64 - margin * 3, height = 32}
lightText.alignX = "right"
lightText.alignY = "center"
lightText.text = "Custom Light Text"
lightText.font.name = "Quicksand-Light"

local regularText = GUI.createElement("text")
regularText.position = {x = sw / 2 - 512 + margin * 2 + 64, y = row + margin * 2 + 32}
regularText.size = {width = 512 - 64 - margin * 3, height = 32}
regularText.alignX = "right"
regularText.alignY = "center"
regularText.text = "Custom Regular Text"
lightText.font.name = "Quicksand-Regular"

local boldText = GUI.createElement("text")
boldText.position = {x = sw / 2 - 512 + margin * 2 + 64, y = row + margin * 3 + 64}
boldText.size = {width = 512 - 64 - margin * 3, height = 32}
boldText.alignX = "right"
boldText.alignY = "center"
boldText.text = "Custom Bold Text"
boldText.font.name = "Quicksand-Bold"

local button = GUI.createElement("button")
button.text = "Button"
button.position = {x = sw / 2 - 512 + margin, y = row + margin + 128 + 32 - 16}
button.size = {width = 512 - 2 * margin, height = 56}
button.borderRadius = radius

local textWindow = GUI.createElement("rectangle")
textWindow.position = {x = sw / 2 + margin, y = sh / 2 - 256 + margin}
textWindow.size = {width = 512 - margin * 2, height = 256 - margin * 2}
textWindow.color.background = GUI.changeColor(color.dark, _, _, _, -128)
textWindow.borderRadius = radius

local scroll = GUI.createElement("scroll")
scroll.position = {x = sw / 2 + margin, y = sh / 2 - 256 + margin * 2}
scroll.size = {width = 512 - margin * 3, height = 256 - margin * 4}
scroll.scrollWidth = 12
scroll.borderRadius = radius
scroll.color.primary = color.gray

scroll.scrollSpeed = 0.003

local scrollLabel = GUI.createElement("text")
scrollLabel.position = {x = margin, y = 0}
scrollLabel.size = {width = 512 - margin * 5 - scroll.scrollWidth, height = 2048}
scrollLabel.parent = scroll
scrollLabel.font.size = 16
scrollLabel.text = [[
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean vitae tellus augue. Suspendisse dui magna, scelerisque sagittis volutpat sed, fringilla rhoncus nisi. Maecenas augue lacus, feugiat condimentum imperdiet eu, volutpat sit amet orci. Proin placerat rhoncus metus, nec tincidunt nisi malesuada eu. Nunc sodales eu lectus id sagittis. In hac habitasse platea dictumst. Aenean vel orci ut orci laoreet facilisis. Proin viverra laoreet elit ut dapibus.

  Integer mollis, enim eget convallis ullamcorper, ligula lectus maximus sem, nec ornare eros augue eu est. Proin sodales, nisi eget rutrum sagittis, arcu nunc fermentum magna, sit amet hendrerit lacus eros vitae quam. Curabitur scelerisque ullamcorper purus vel pellentesque. Cras ultricies nulla quis quam dapibus, et posuere augue ultricies. Nam pellentesque urna et auctor maximus. Donec leo purus, molestie sed nisi vitae, vulputate egestas arcu. Curabitur commodo quam ac arcu fermentum sagittis. Integer scelerisque auctor mauris, eu sollicitudin est hendrerit a. Fusce quis lacus at felis tempor lobortis nec vel nisl. Morbi elementum auctor dolor, a fringilla neque efficitur a. Sed nec ex eget lorem sollicitudin ultricies at in diam. Maecenas ut risus id massa aliquam tincidunt sit amet non elit. Sed fringilla id mauris quis aliquam. Fusce eu augue massa. Integer vehicula in erat eu ullamcorper. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.
  
  Ut lectus lacus, luctus ut quam ut, imperdiet eleifend lacus. Nulla egestas elit imperdiet euismod suscipit. Sed accumsan ipsum id dapibus lacinia. Integer sed feugiat metus. Integer fringilla felis quis magna dapibus, ullamcorper fringilla elit condimentum. Proin porttitor consequat eleifend. Integer posuere leo risus, sed dapibus ipsum pulvinar ac. Vestibulum cursus id odio vel pellentesque.
  
  In lectus enim, pulvinar non bibendum nec, convallis nec dui. Vivamus vulputate pellentesque libero, vel blandit augue eleifend eu. In sit amet lorem dapibus, commodo urna non, volutpat enim. Mauris pulvinar turpis maximus eros venenatis laoreet. Phasellus dictum varius augue in pellentesque. Vestibulum varius varius nulla, at pellentesque ante luctus vel. Cras consequat condimentum faucibus. Integer blandit mauris sed interdum cursus. Etiam id nibh eros. Donec nec dapibus orci, nec fringilla tellus. Aliquam posuere metus rhoncus, luctus nulla eu, congue leo. Curabitur at ornare sapien. In id erat metus. Donec fringilla eget nisl vel malesuada. Integer laoreet blandit dolor, id condimentum augue feugiat quis. Sed eu est tellus.
  
  Suspendisse eget dapibus quam. Pellentesque tempor ligula eu eros gravida, ac ultricies lorem lacinia. Suspendisse congue elit gravida ante egestas scelerisque. Praesent aliquam neque at efficitur rhoncus. Vestibulum vulputate justo sit amet massa sagittis, mattis venenatis felis euismod. Aliquam aliquet purus ac pretium cursus. Integer dapibus, sem quis rutrum efficitur, nibh massa auctor lectus, ac ullamcorper leo ex a felis. Duis condimentum congue justo, posuere faucibus purus blandit eget. Nam eget mauris a lectus scelerisque hendrerit non vel quam. Proin luctus lectus non leo vestibulum tempus.
  
  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean vitae tellus augue. Suspendisse dui magna, scelerisque sagittis volutpat sed, fringilla rhoncus nisi. Maecenas augue lacus, feugiat condimentum imperdiet eu, volutpat sit amet orci. Proin placerat rhoncus metus, nec tincidunt nisi malesuada eu. Nunc sodales eu lectus id sagittis. In hac habitasse platea dictumst. Aenean vel orci ut orci laoreet facilisis. Proin viverra laoreet elit ut dapibus.

]]
scrollLabel.wordBreak = true

local image = GUI.createElement("image")
image.image = dxCreateTexture("example.png")
image.position = {x = sw / 2 + margin, y = sh / 2 + margin}
image.size = {width = 512 - margin * 2, height = 256 - margin * 2}
image.color.image = color.flat.red
image.rotation = 8

bindKey("F3", "down", function()
  showCursor(not isCursorShowing())
end)

--[[

local texx = GUI.createElement("text")
texx.position = {x = 0, y = 0}
texx.size = {width = 1920, height = 1080}
texx.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas imperdiet enim sed nunc efficitur, in laoreet est ultricies. Donec lobortis dolor tempus volutpat dapibus. Vivamus nunc augue, dignissim quis auctor dapibus, gravida eget nunc. Aliquam id velit condimentum, pretium libero quis, facilisis diam. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec aliquet eu felis eu molestie. Integer iaculis, tellus id vehicula iaculis, velit nunc finibus sapien, sed viverra libero mi vitae magna. Vestibulum vestibulum neque odio, in dapibus augue pellentesque in. Curabitur vehicula viverra accumsan. Nunc varius est id eros euismod dapibus. Nam mauris felis, placerat id luctus scelerisque, tincidunt eget diam. Interdum et malesuada fames ac ante ipsum primis in faucibus. Nunc vulputate vestibulum hendrerit."
texx.font.size = 32
texx.wordBreak = true
texx.alignX = "left"
texx.alignY = "top"
texx.renderTarget = true

local x, y, z = getElementPosition(localPlayer)
z = z - 2
local size = 4
addEventHandler("onClientRender", root, function()
  dxDrawMaterialLine3D(x+size, y+size, z-0.95 + 4.5, x+size, y+size, z-0.95, texx.texture, size * 2, tocolor(255, 255, 255, 255), x, y, z)
end)

]]--