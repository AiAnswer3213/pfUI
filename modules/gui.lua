pfUI:RegisterModule("gui", function ()
  local function PrepareDropDownButton(index)
    if index > _G.UIDROPDOWNMENU_MAXBUTTONS then
      for i=1,3 do
        local name = "DropDownList" .. i .. "Button" .. index
        local parent = _G["DropDownList" .. i]
        _G.UIDROPDOWNMENU_MAXBUTTONS = index
        _G[name] = CreateFrame("Button", name, parent, "UIDropDownMenuButtonTemplate")
        _G[name]:SetID(index)
      end
    end
  end

  local function CreateConfig(ufunc, parent, caption, category, config, widget, values, skip, named, type)
    -- parent object placement
    if parent.objectCount == nil then
      parent.objectCount = 1
    elseif not skip then
      parent.objectCount = parent.objectCount + 1
      parent.lineCount = 1
    end

    if skip then
      if parent.lineCount == nil then
        parent.lineCount = 1
      end

      if skip then
        parent.lineCount = parent.lineCount + 1
      end
    end

    if not caption then return end

    -- basic frame
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(420)
    frame:SetHeight(25)
    frame:SetPoint("TOPLEFT", 25, parent.objectCount * -25)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function()
      this:SetBackdropBorderColor(1,1,1,.08)
    end)

    frame:SetScript("OnLeave", function()
      this:SetBackdropBorderColor(1,1,1,.04)
    end)

    if not widget or (widget and widget ~= "button") then
      frame:SetBackdrop(pfUI.backdrop_hover)
      frame:SetBackdropBorderColor(1,1,1,.04)

      if not ufunc and widget ~= "header" and C.gui.reloadmarker == "1" then
        caption = caption .. " [|cffffaaaa!|r]"
      end

      -- caption
      frame.caption = frame:CreateFontString("Status", "LOW", "GameFontNormal")
      frame.caption:SetFont(pfUI.font_default, C.global.font_size + 2, "OUTLINE")
      frame.caption:SetPoint("LEFT", frame, "LEFT", 3, 1)
      frame.caption:SetFontObject(GameFontWhite)
      frame.caption:SetJustifyH("LEFT")
      frame.caption:SetText(caption)
    end

    if category == "CVAR" then
      category = {}
      category[config] = tostring(GetCVar(config))
      ufunc = function()
        SetCVar(this:GetParent().config, this:GetParent().category[config])
      end
    end

    if category == "GVAR" then
      category = {}
      category[config] = tostring(_G[config] or 0)

      local update = ufunc

      ufunc = function()
        UIOptionsFrame_Load()
        _G[config] = this:GetChecked() and 1 or nil
        UIOptionsFrame_Save()
        if update then
          update()
        end
      end
    end

    frame.category = category
    frame.config = config

    if widget == "color" then
      -- color picker
      frame.color = CreateFrame("Button", nil, frame)
      frame.color:SetWidth(24)
      frame.color:SetHeight(12)
      CreateBackdrop(frame.color)
      frame.color:SetPoint("RIGHT" , -5, 1)
      frame.color.prev = frame.color.backdrop:CreateTexture("OVERLAY")
      frame.color.prev:SetAllPoints(frame.color)

      local cr, cg, cb, ca = strsplit(",", category[config])
      if not cr or not cg or not cb or not ca then
        cr, cg, cb, ca = 1, 1, 1, 1
      end
      frame.color.prev:SetTexture(cr,cg,cb,ca)

      frame.color:SetScript("OnClick", function()
        local cr, cg, cb, ca = strsplit(",", category[config])
        if not cr or not cg or not cb or not ca then
          cr, cg, cb, ca = 1, 1, 1, 1
        end
        local preview = this.prev

        function ColorPickerFrame.func()
          local r,g,b = ColorPickerFrame:GetColorRGB()
          local a = 1 - OpacitySliderFrame:GetValue()

          r = round(r, 1)
          g = round(g, 1)
          b = round(b, 1)
          a = round(a, 1)

          preview:SetTexture(r,g,b,a)

          if not this:GetParent():IsShown() then
            category[config] = r .. "," .. g .. "," .. b .. "," .. a
            if ufunc then ufunc() else pfUI.gui.settingChanged = true end
          end
        end

        function ColorPickerFrame.cancelFunc()
          preview:SetTexture(cr,cg,cb,ca)
        end

        ColorPickerFrame.opacityFunc = ColorPickerFrame.func
        ColorPickerFrame.element = this
        ColorPickerFrame.opacity = 1 - ca
        ColorPickerFrame.hasOpacity = 1
        ColorPickerFrame:SetColorRGB(cr,cg,cb)
        ColorPickerFrame:SetFrameStrata("DIALOG")
        ShowUIPanel(ColorPickerFrame)
      end)

      -- hide shadows on wrong stratas
      if frame.color.backdrop_shadow then
        frame.color.backdrop_shadow:Hide()
      end
    end

    if widget == "warning" then
      CreateBackdrop(frame, nil, true)
      frame:SetBackdropBorderColor(1,.5,.5)
      frame:SetHeight(50)
      frame:SetPoint("TOPLEFT", 25, parent.objectCount * -35)
      parent.objectCount = parent.objectCount + 2
      frame.caption:SetJustifyH("CENTER")
      frame.caption:SetJustifyV("CENTER")
    end

    if widget == "header" then
      frame:SetBackdrop(nil)
      frame:SetHeight(40)
      parent.objectCount = parent.objectCount + 1
      frame.caption:SetJustifyH("LEFT")
      frame.caption:SetJustifyV("BOTTOM")
      frame.caption:SetTextColor(.2,1,.8,1)
      frame.caption:SetAllPoints(frame)
    end

    -- use text widget (default)
    if not widget or widget == "text" then
      -- input field
      frame.input = CreateFrame("EditBox", nil, frame)
      CreateBackdrop(frame.input, nil, true)
      frame.input:SetTextInsets(5, 5, 5, 5)
      frame.input:SetTextColor(.2,1,.8,1)
      frame.input:SetJustifyH("RIGHT")

      frame.input:SetWidth(100)
      frame.input:SetHeight(18)
      frame.input:SetPoint("RIGHT" , -3, 0)
      frame.input:SetFontObject(GameFontNormal)
      frame.input:SetAutoFocus(false)
      frame.input:SetText(category[config])
      frame.input:SetScript("OnEscapePressed", function(self)
        this:ClearFocus()
      end)

      frame.input:SetScript("OnTextChanged", function(self)
        if ( type and type ~= "number" ) or tonumber(this:GetText()) then
          if this:GetText() ~= this:GetParent().category[this:GetParent().config] then
            this:GetParent().category[this:GetParent().config] = this:GetText()
            if ufunc then ufunc() else pfUI.gui.settingChanged = true end
          end
          this:SetTextColor(.2,1,.8,1)
        else
          this:SetTextColor(1,.3,.3,1)
        end
      end)

      -- hide shadows on wrong stratas
      if frame.input.backdrop_shadow then
        frame.input.backdrop_shadow:Hide()
      end
    end

    -- use button widget
    if widget == "button" then
      frame.button = CreateFrame("Button", "pfButton", frame, "UIPanelButtonTemplate")
      CreateBackdrop(frame.button, nil, true)
      SkinButton(frame.button)
      frame.button:SetWidth(100)
      frame.button:SetHeight(20)
      frame.button:SetPoint("TOPRIGHT", -(parent.lineCount-1) * 105, -5)
      frame.button:SetText(caption)
      frame.button:SetTextColor(1,1,1,1)
      frame.button:SetScript("OnClick", values)

      -- hide shadows on wrong stratas
      if frame.button.backdrop_shadow then
        frame.button.backdrop_shadow:Hide()
      end
    end

    -- use checkbox widget
    if widget == "checkbox" then
      -- input field
      frame.input = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
      frame.input:SetNormalTexture("")
      frame.input:SetPushedTexture("")
      frame.input:SetHighlightTexture("")
      CreateBackdrop(frame.input, nil, true)
      frame.input:SetWidth(14)
      frame.input:SetHeight(14)
      frame.input:SetPoint("RIGHT" , -5, 1)
      frame.input:SetScript("OnClick", function ()
        if this:GetChecked() then
          this:GetParent().category[this:GetParent().config] = "1"
        else
          this:GetParent().category[this:GetParent().config] = "0"
        end

        if ufunc then ufunc() else pfUI.gui.settingChanged = true end
      end)

      if category[config] == "1" then frame.input:SetChecked() end

      -- hide shadows on wrong stratas
      if frame.input.backdrop_shadow then
        frame.input.backdrop_shadow:Hide()
      end
    end

    -- use dropdown widget
    if widget == "dropdown" and values then
      if not pfUI.gui.ddc then pfUI.gui.ddc = 1 else pfUI.gui.ddc = pfUI.gui.ddc + 1 end
      local name = pfUI.gui.ddc
      if named then name = named end

      frame.input = CreateFrame("Frame", "pfUIDropDownMenu" .. name, frame, "UIDropDownMenuTemplate")
      frame.input:ClearAllPoints()
      frame.input:SetPoint("RIGHT", 16, -3)
      frame.input.values = values

      UIDropDownMenu_SetWidth(160, frame.input)
      UIDropDownMenu_SetButtonWidth(160, frame.input)
      UIDropDownMenu_JustifyText("RIGHT", frame.input)
      UIDropDownMenu_Initialize(frame.input, function()
        local info = {}
        for i, k in pairs(frame.input.values) do
          -- create new dropdown buttons when we reach the limit
          PrepareDropDownButton(i)

          -- get human readable
          local value, text = strsplit(":", k)
          text = text or value

          info.text = text
          info.checked = false
          info.func = function()
            UIDropDownMenu_SetSelectedID(frame.input, this:GetID(), 0)
            UIDropDownMenu_SetText(this:GetText(), frame.input)
            if category[config] ~= value then
              category[config] = value
              if ufunc then ufunc() else pfUI.gui.settingChanged = true end
            end
          end

          UIDropDownMenu_AddButton(info)
          if category[config] == value then
            frame.input.current = i
          end
        end
      end)
      UIDropDownMenu_SetSelectedID(frame.input, frame.input.current)

      SkinDropDown(frame.input)
      frame.input.backdrop:Hide()
      frame.input.button.icon:SetParent(frame.input.button.backdrop)

      -- hide shadows on wrong stratas
      if frame.input.backdrop_shadow then
        frame.input.backdrop_shadow:Hide()
        frame.input.button.backdrop_shadow:Hide()
      end
    end

    -- use list widget
    if widget == "list" then
      if not pfUI.gui.ddc then pfUI.gui.ddc = 1 else pfUI.gui.ddc = pfUI.gui.ddc + 1 end
      local name = pfUI.gui.ddc
      if named then name = named end

      frame.input = CreateFrame("Frame", "pfUIDropDownMenu" .. name, frame, "UIDropDownMenuTemplate")
      frame.input:ClearAllPoints()
      frame.input:SetPoint("RIGHT" , -22, -3)
      frame.category = category
      frame.config = config

      frame.input.Refresh = function()
        local function CreateValues()
          for i, val in pairs({strsplit("#", category[config])}) do
            -- create new dropdown buttons when we reach the limit
            PrepareDropDownButton(i)

            UIDropDownMenu_AddButton({
              ["text"] = val,
              ["checked"] = false,
              ["func"] = function()
                UIDropDownMenu_SetSelectedID(frame.input, this:GetID(), 0)
              end
            })
          end
        end

        UIDropDownMenu_Initialize(frame.input, CreateValues)
        UIDropDownMenu_SetText("", frame.input)
      end

      frame.input:Refresh()

      UIDropDownMenu_SetWidth(160, frame.input)
      UIDropDownMenu_SetButtonWidth(160, frame.input)
      UIDropDownMenu_JustifyText("RIGHT", frame.input)
      UIDropDownMenu_SetSelectedID(frame.input, frame.input.current)

      SkinDropDown(frame.input)
      frame.input.backdrop:Hide()
      frame.input.button.icon:SetParent(frame.input.button.backdrop)

      frame.add = CreateFrame("Button", "pfUIDropDownMenu" .. name .. "Add", frame, "UIPanelButtonTemplate")
      SkinButton(frame.add)
      frame.add:SetWidth(18)
      frame.add:SetHeight(18)
      frame.add:SetPoint("RIGHT", -21, 0)
      frame.add:GetFontString():SetPoint("CENTER", 1, 0)
      frame.add:SetText("+")
      frame.add:SetTextColor(.5,1,.5,1)
      frame.add:SetScript("OnClick", function()
        CreateQuestionDialog(T["New entry:"], function()
            category[config] = category[config] .. "#" .. this:GetParent().input:GetText()
            if ufunc then ufunc() else pfUI.gui.settingChanged = true end
          end, false, true)
      end)

      frame.del = CreateFrame("Button", "pfUIDropDownMenu" .. name .. "Del", frame, "UIPanelButtonTemplate")
      SkinButton(frame.del)
      frame.del:SetWidth(18)
      frame.del:SetHeight(18)
      frame.del:SetPoint("RIGHT", -2, 0)
      frame.del:GetFontString():SetPoint("CENTER", 1, 0)
      frame.del:SetText("-")
      frame.del:SetTextColor(1,.5,.5,1)
      frame.del:SetScript("OnClick", function()
        local sel = UIDropDownMenu_GetSelectedID(frame.input)
        local newconf = ""
        for id, val in pairs({strsplit("#", category[config])}) do
          if id ~= sel then newconf = newconf .. "#" .. val end
        end
        category[config] = newconf
        frame.input:Refresh()
        if ufunc then ufunc() else pfUI.gui.settingChanged = true end
      end)

      -- hide shadows on wrong stratas
      if frame.input.backdrop_shadow then
        frame.input.backdrop_shadow:Hide()
        frame.input.button.backdrop_shadow:Hide()
        frame.add.backdrop_shadow:Hide()
        frame.del.backdrop_shadow:Hide()
      end
    end

    return frame
  end

  pfUI.gui = CreateFrame("Frame", "pfConfigGUI", UIParent)
  pfUI.gui:Hide()
  pfUI.gui:SetWidth(640)
  pfUI.gui:SetHeight(480)
  pfUI.gui:SetFrameStrata("DIALOG")
  pfUI.gui:SetPoint("CENTER", 0, 0)
  table.insert(UISpecialFrames, "pfConfigGUI")

  function pfUI.gui:Reload()
    CreateQuestionDialog(T["Some settings need to reload the UI to take effect.\nDo you want to reloadUI now?"],
      function()
        pfUI.gui.settingChanged = nil
        ReloadUI()
      end)
  end

  pfUI.gui:SetScript("OnShow",function()
    pfUI.gui.settingChanged = pfUI.gui.delaySettingChanged
    pfUI.gui.delaySettingChanged = nil

    -- exit unlock mode
    if pfUI.unlock and pfUI.unlock:IsShown() then
      pfUI.unlock:Hide()
    end

    -- exit hoverbind mode
    if pfUI.hoverbind and pfUI.hoverbind:IsShown() then
      pfUI.hoverbind:Hide()
    end
  end)

  pfUI.gui:SetScript("OnHide",function()
    if ColorPickerFrame and ColorPickerFrame:IsShown() then
      ColorPickerFrame:Hide()
    end

    if pfUI.gui.settingChanged then
      pfUI.gui:Reload()
    end
    pfUI.gui:Hide()
  end)


  CreateBackdrop(pfUI.gui, nil, true, 0.75)

  pfUI.gui:SetMovable(true)
  pfUI.gui:EnableMouse(true)
  pfUI.gui:SetScript("OnMouseDown",function()
    this:StartMoving()
  end)

  pfUI.gui:SetScript("OnMouseUp",function()
    this:StopMovingOrSizing()
  end)

  -- gui decorations
  pfUI.gui.title = pfUI.gui:CreateFontString("Status", "LOW", "GameFontNormal")
  pfUI.gui.title:SetFontObject(GameFontWhite)
  pfUI.gui.title:SetPoint("TOPLEFT", pfUI.gui, "TOPLEFT", 5, -8)
  pfUI.gui.title:SetWidth(73)
  pfUI.gui.title:SetJustifyH("RIGHT")
  pfUI.gui.title:SetFont("Interface\\AddOns\\pfUI\\fonts\\DieDieDie.ttf", 16)
  pfUI.gui.title:SetText("|cff33ffccpf|rUI")

  pfUI.gui.version = pfUI.gui:CreateFontString("Status", "LOW", "GameFontNormal")
  pfUI.gui.version:SetFontObject(GameFontWhite)
  pfUI.gui.version:SetPoint("TOPLEFT", pfUI.gui, "TOPLEFT", 82, -8)
  pfUI.gui.version:SetWidth(75)
  pfUI.gui.version:SetJustifyH("LEFT")
  pfUI.gui.version:SetFont("Interface\\AddOns\\pfUI\\fonts\\Myriad-Pro.ttf", 12)
  pfUI.gui.version:SetText("|caaaaaaaav" .. pfUI.version.string)

  pfUI.gui.close = CreateFrame("Button", "pfQuestionDialogClose", pfUI.gui)
  pfUI.gui.close:SetPoint("TOPRIGHT", -5, -5)
  pfUI.api.CreateBackdrop(pfUI.gui.close)
  pfUI.gui.close:SetHeight(12)
  pfUI.gui.close:SetWidth(12)
  pfUI.gui.close.texture = pfUI.gui.close:CreateTexture("pfQuestionDialogCloseTex")
  pfUI.gui.close.texture:SetTexture("Interface\\AddOns\\pfUI\\img\\close")
  pfUI.gui.close.texture:ClearAllPoints()
  pfUI.gui.close.texture:SetAllPoints(pfUI.gui.close)
  pfUI.gui.close.texture:SetVertexColor(1,.25,.25,1)
  pfUI.gui.close:SetScript("OnEnter", function ()
    this.backdrop:SetBackdropBorderColor(1,.25,.25,1)
  end)

  pfUI.gui.close:SetScript("OnLeave", function ()
    pfUI.api.CreateBackdrop(this)
  end)

  pfUI.gui.close:SetScript("OnClick", function()
   this:GetParent():Hide()
  end)

  -- update functions
  local update = setmetatable({}, { __index = function(tab,key)
    local value = tostring(key)
    if pfUI[value] and pfUI[value].UpdateConfig then
      return function() pfUI[value]:UpdateConfig() end
    elseif pfUI.uf[value] and pfUI.uf[value].UpdateConfig then
      return function() pfUI.uf[value]:UpdateConfig() end
    end
  end})

  -- initialize dropdown menus
  pfUI.gui.dropdowns = { }

  pfUI.gui.dropdowns.languages = {
    -- "deDE:German",
    -- "enGB:British English",
    "enUS:English",
    "esES:Spanish",
    --"esMX:Spanish (Latin American)",
    "frFR:French",
    "koKR:Korean",
    "ruRU:Russian",
    "zhCN:Chinese (simplified; China)",
    "zhTW:Chinese (traditional; Taiwan)",
    -- http://wowprogramming.com/docs/api/GetLocale
  }

  -- dropdown menu items
  pfUI.gui.dropdowns.fonts = {
    "Interface\\AddOns\\pfUI\\fonts\\BigNoodleTitling.ttf:BigNoodleTitling",
    "Interface\\AddOns\\pfUI\\fonts\\Continuum.ttf:Continuum",
    "Interface\\AddOns\\pfUI\\fonts\\DieDieDie.ttf:DieDieDie",
    "Interface\\AddOns\\pfUI\\fonts\\Expressway.ttf:Expressway",
    "Interface\\AddOns\\pfUI\\fonts\\Homespun.ttf:Homespun",
    "Interface\\AddOns\\pfUI\\fonts\\Hooge.ttf:Hooge",
    "Interface\\AddOns\\pfUI\\fonts\\Myriad-Pro.ttf:Myriad-Pro",
    "Interface\\AddOns\\pfUI\\fonts\\PT-Sans-Narrow-Bold.ttf:PT-Sans-Narrow-Bold",
    "Interface\\AddOns\\pfUI\\fonts\\PT-Sans-Narrow-Regular.ttf:PT-Sans-Narrow-Regular"
  }

  -- add locale dependent client fonts to the list
  if GetLocale() == "enUS" or GetLocale() == "frFR" or GetLocale() == "deDE" or GetLocale() == "ruRU" then
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\ARIALN.TTF:ARIALN")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FRIZQT__.TTF:FRIZQT")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\MORPHEUS.TTF:MORPHEUS")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\SKURRI.TTF:SKURRI")
  elseif GetLocale() == "koKR" then
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\2002.TTF:2002")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\2002B.TTF:2002B")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\ARIALN.TTF:ARIALN")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FRIZQT__.TTF:FRIZQT")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\K_Damage.TTF:K_Damage")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\K_Pagetext.TTF:K_Pagetext")
  elseif GetLocale() == "zhCN" then
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\ARIALN.TTF:ARIALN")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FRIZQT__.TTF:FRIZQT")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FZBWJW.TTF:FZBWJW")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FZJZJW.TTF:FZJZJW")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FZLBJW.TTF:FZLBJW")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FZXHJW.TTF:FZXHJW")
    table.insert(pfUI.gui.dropdowns.fonts, "Fonts\\FZXHLJW.TTF:FZXHLJW")
  end

  pfUI.gui.dropdowns.scaling = {
    "0:" .. T["Off"],
    "4:" .. T["Huge (PixelPerfect)"],
    "5:" .. T["Large"],
    "6:" .. T["Medium"],
    "7:" .. T["Small"],
    "8:" .. T["Tiny (PixelPerfect)"],
  }

  pfUI.gui.dropdowns.uf_animationspeed = {
    "1:" .. T["Instant"],
    "2:" .. T["Very Fast"],
    "3:" .. T["Fast"],
    "5:" .. T["Medium"],
    "8:" .. T["Slow"],
    "13:" .. T["Very Slow"],
  }

  pfUI.gui.dropdowns.uf_bartexture = {
    "Interface\\AddOns\\pfUI\\img\\bar:pfUI",
    "Interface\\AddOns\\pfUI\\img\\bar_tukui:TukUI",
    "Interface\\AddOns\\pfUI\\img\\bar_elvui:ElvUI",
    "Interface\\AddOns\\pfUI\\img\\bar_striped:Striped",
    "Interface\\TargetingFrame\\UI-StatusBar:Wow Status",
    "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar:Wow Skill"
  }

  pfUI.gui.dropdowns.uf_rangecheckinterval = {
    "1:" .. T["Very Fast"],
    "2:" .. T["Fast"],
    "4:" .. T["Medium"],
    "8:" .. T["Slow"],
    "16:" .. T["Very Slow"],
  }

  pfUI.gui.dropdowns.uf_powerbar_position = {
    "TOPLEFT:" .. T["Left"],
    "TOP:" .. T["Center"],
    "TOPRIGHT:" .. T["Right"]
  }

  pfUI.gui.dropdowns.uf_portrait_position = {
    "bar:" .. T["Healthbar Embedded"],
    "left:" .. T["Left"],
    "right:" .. T["Right"],
    "off:" .. T["Disabled"]
  }

  pfUI.gui.dropdowns.uf_buff_position = {
    "TOPLEFT:" .. T["Top Left"],
    "TOPRIGHT:" .. T["Top Right"],
    "BOTTOMLEFT:" .. T["Bottom Left"],
    "BOTTOMRIGHT:" .. T["Bottom Right"],
    "off:" .. T["Disabled"]
  }

  pfUI.gui.dropdowns.uf_debuff_indicator = {
    "0:" .. T["Disabled"],
    "1:" .. T["Legacy"],
    "2:" .. T["Glow"],
    "3:" .. T["Square"],
    "4:" .. T["Icon"]
  }

  pfUI.gui.dropdowns.uf_debuff_indicator_size = {
    ".10:10%",
    ".25:25%",
    ".35:35%",
    ".50:50%",
    ".65:65%",
    ".75:75%",
    ".90:90%",
  }

  pfUI.gui.dropdowns.uf_layout = {
    "default:" .. T["Default"],
    "tukui:TukUI"
  }

  pfUI.gui.dropdowns.uf_texts = {
    "none:" .. T["Disable"],
    "unit:" .. T["Unit String"],
    "name:" .. T["Name"],
    "nameshort:" .. T["Name (Short)"],
    "level:" .. T["Level"],
    "class:" .. T["Class"],
    "healthdyn:" .. T["Health - Auto"],
    "health:" .. T["Health - Current"],
    "healthmax:" .. T["Health - Max"],
    "healthperc:" .. T["Health - Percentage"],
    "healthmiss:" .. T["Health - Missing"],
    "healthminmax:" .. T["Health - Min/Max"],
    "powerdyn:" .. T["Mana - Auto"],
    "power:" .. T["Mana - Current"],
    "powermax:" .. T["Mana - Max"],
    "powerperc:" .. T["Mana - Percentage"],
    "powermiss:" .. T["Mana - Missing"],
    "powerminmax:" .. T["Mana - Min/Max"],
  }

  pfUI.gui.dropdowns.panel_values = {
    "none:" .. T["Disable"],
    "time:" .. T["Clock"],
    "fps:" .. T["FPS & Ping"],
    "exp:" .. T["XP Percentage"],
    "gold:" .. T["Gold"],
    "friends:" .. T["Friends Online"],
    "guild:" .. T["Guild Online"],
    "durability:" .. T["Item Durability"],
    "zone:" .. T["Zone Name"],
    "combat:" .. T["Combat Timer"],
    "ammo:" .. T["Ammo Counter"],
    "soulshard:" .. T["Soulshard Counter"],
    "bagspace:" .. T["Bagspace"]
  }

  pfUI.gui.dropdowns.tooltip_position = {
    "bottom:" .. T["Bottom"],
    "chat:" .. T["Dodge"],
    "cursor:" .. T["Cursor"]
  }

  pfUI.gui.dropdowns.tooltip_align = {
    "native:" .. T["Native"],
    "top:" .. T["Top"],
    "left:" .. T["Left"],
    "right:" .. T["Right"]
  }

  pfUI.gui.dropdowns.gmserver_text = {
    "elysium:" .. T["Elysium Based Core"],
  }

  pfUI.gui.dropdowns.buffbarfilter = {
    "none:"      .. T["None"],
    "whitelist:" .. T["Whitelist"],
    "blacklist:" .. T["Blacklist"],
  }

  pfUI.gui.dropdowns.buffbarsort = {
    "asc:" .. T["Ascending"],
    "desc:" .. T["Descending"],
  }

  pfUI.gui.dropdowns.minimap_cords_position = {
    "topleft:" .. T["Top Left"],
    "topright:" .. T["Top Right"],
    "bottomleft:" .. T["Bottom Left"],
    "bottomright:" .. T["Bottom Right"],
    "off:" .. T["Disabled"]
  }

  pfUI.gui.dropdowns.positions = {
    "TOPLEFT:" .. T["Top Left"],
    "TOP:" .. T["Top"],
    "TOPRIGHT:" .. T["Top Right"],
    "LEFT:" .. T["Left"],
    "CENTER:" .. T["Center"],
    "RIGHT:" .. T["Right"],
    "BOTTOMLEFT:" .. T["Bottom Left"],
    "BOTTOM:" .. T["Bottom"],
    "BOTTOMRIGHT:" .. T["Bottom Right"],
  }

  pfUI.gui.dropdowns.num_actionbar_buttons = BarLayoutOptions(NUM_ACTIONBAR_BUTTONS)
  pfUI.gui.dropdowns.num_shapeshift_slots = BarLayoutOptions(NUM_SHAPESHIFT_SLOTS)
  pfUI.gui.dropdowns.num_pet_action_slots = BarLayoutOptions(NUM_PET_ACTION_SLOTS)

  pfUI.gui.dropdowns.loot_rarity = {}
  for i=0, getn(_G.ITEM_QUALITY_COLORS)-2  do
    local entry = string.format("%d:%s", i, string.format("%s%s%s", _G.ITEM_QUALITY_COLORS[i].hex, _G[string.format("ITEM_QUALITY%d_DESC",i)], FONT_COLOR_CODE_CLOSE))
    table.insert(pfUI.gui.dropdowns.loot_rarity, entry)
  end

  -- main tab frame
  pfUI.gui.tabs = CreateTabFrame(pfUI.gui, "LEFT")
  pfUI.gui.tabs:SetPoint("TOPLEFT", pfUI.gui, "TOPLEFT", 0, -25)
  pfUI.gui.tabs:SetPoint("BOTTOMRIGHT", pfUI.gui, "BOTTOMRIGHT", 0, 0)


  -- [[ Settings ]]
  pfUI.gui.tabs.settings = pfUI.gui.tabs:CreateTabChild(T["Settings"], nil, nil, nil, true)
  pfUI.gui.tabs.settings.tabs = CreateTabFrame(pfUI.gui.tabs.settings, "TOP", true)

  -- >> Global
  pfUI.gui.tabs.settings.tabs.general = pfUI.gui.tabs.settings.tabs:CreateTabChild(T["General"], true)
  pfUI.gui.tabs.settings.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      local header = CreateConfig(nil, this, T["Profile"], nil, nil, "header")
      header:GetParent().objectCount = header:GetParent().objectCount - 1
      header:SetHeight(20)

      local values = {}
      for name, config in pairs(pfUI_profiles) do table.insert(values, name) end

      local function pfUpdateProfiles()
        local values = {}
        for name, config in pairs(pfUI_profiles) do table.insert(values, name) end
        pfUIDropDownMenuProfile.values = values
        UIDropDownMenu_SetSelectedID(pfUIDropDownMenuProfile, 0, 0)
        UIDropDownMenu_SetText("", pfUIDropDownMenuProfile)
      end

      CreateConfig(nil, this, T["Select profile"], C.global, "profile", "dropdown", values, false, "Profile")

      -- load profile
      CreateConfig(nil, this, T["Load profile"], C.global, "profile", "button", function()
        if C.global.profile and pfUI_profiles[C.global.profile] then
          CreateQuestionDialog(T["Load profile"] .. " '|cff33ffcc" .. C.global.profile .. "|r'?", function()
            local selp = C.global.profile
            _G["pfUI_config"] = CopyTable(pfUI_profiles[C.global.profile])
            pfUI:LoadConfig()
            C.global.profile = selp
            ReloadUI()
          end)
        end
      end)

      -- delete profile
      CreateConfig(nil, this, T["Delete profile"], C.global, "profile", "button", function()
        if C.global.profile and pfUI_profiles[C.global.profile] then
          CreateQuestionDialog(T["Delete profile"] .. " '|cff33ffcc" .. C.global.profile .. "|r'?", function()
            pfUI_profiles[C.global.profile] = nil
            pfUpdateProfiles()
            this:GetParent():Hide()
          end)
        end
      end, true)

      -- save profile
      CreateConfig(nil, this, T["Save profile"], C.global, "profile", "button", function()
        if C.global.profile and pfUI_profiles[C.global.profile] then
          CreateQuestionDialog(T["Save current settings to profile"] .. " '|cff33ffcc" .. C.global.profile .. "|r'?", function()
            if pfUI_profiles[C.global.profile] then
              pfUI_profiles[C.global.profile] = CopyTable(C)
            end
            this:GetParent():Hide()
          end)
        end
      end, true)

      -- create profile
      CreateConfig(nil, this, T["Create Profile"], C.global, "profile", "button", function()
        CreateQuestionDialog(T["Please enter a name for the new profile.\nExisting profiles sharing the same name will be overwritten."],
        function()
          local profile = this:GetParent().input:GetText()
          local bad = string.gsub(profile,"([%w%s]+)","")
          if bad~="" then
            message("\"" .. bad .. "\" " .. T["is not allowed in profile name"])
          else
            profile = (string.gsub(profile,"^%s*(.-)%s*$", "%1"))
            if profile and profile ~= "" then
              pfUI_profiles[profile] = CopyTable(C)
              pfUpdateProfiles()
              this:GetParent():Hide()
            end
          end
        end, false, true)
      end, true)

      CreateConfig(nil, this, T["Settings"], nil, nil, "header")
      CreateConfig(nil, this, T["Language"], C.global, "language", "dropdown", pfUI.gui.dropdowns.languages)
      CreateConfig(nil, this, T["Enable Region Compatible Font"], C.global, "force_region", "checkbox")
      CreateConfig(nil, this, T["Standard Text Font"], C.global, "font_default", "dropdown", pfUI.gui.dropdowns.fonts)
      CreateConfig(nil, this, T["Standard Text Font Size"], C.global, "font_size")
      CreateConfig(nil, this, T["Unit Frame Text Font"], C.global, "font_unit", "dropdown", pfUI.gui.dropdowns.fonts)
      CreateConfig(nil, this, T["Unit Frame Text Size"], C.global, "font_unit_size")
      CreateConfig(nil, this, T["Scrolling Combat Text Font"], C.global, "font_combat", "dropdown", pfUI.gui.dropdowns.fonts)
      CreateConfig(update["pixelperfect"], this, T["Enable UI-Scale"], C.global, "pixelperfect", "dropdown", pfUI.gui.dropdowns.scaling)
      CreateConfig(nil, this, T["Enable Offscreen Frame Positions"], C.global, "offscreen", "checkbox")
      CreateConfig(nil, this, T["Enable Single Line UIErrors"], C.global, "errors_limit", "checkbox")
      CreateConfig(nil, this, T["Disable All UIErrors"], C.global, "errors_hide", "checkbox")
      CreateConfig(nil, this, T["Highlight Settings That Require Reload"], C.gui, "reloadmarker", "checkbox")

      -- Delete / Reset
      CreateConfig(nil, this, T["Delete / Reset"], nil, nil, "header")

      CreateConfig(nil, this, T["|cffff5555EVERYTHING"], C.global, "profile", "button", function()
        CreateQuestionDialog(T["Do you really want to reset |cffffaaaaEVERYTHING|r?\n\nThis will reset:\n - Current Configuration\n - Current Frame Positions\n - Firstrun Wizard\n - Addon Cache\n - Saved Profiles"],
          function()
            _G["pfUI_init"] = {}
            _G["pfUI_config"] = {}
            _G["pfUI_playerDB"] = {}
            _G["pfUI_profiles"] = {}
            pfUI:LoadConfig()
            this:GetParent():Hide()
            pfUI.gui:Reload()
          end)
      end)

      CreateConfig(nil, this, T["Configuration"], C.global, "profile", "button", function()
        CreateQuestionDialog(T["Do you really want to reset your configuration?\nThis also includes frame positions"],
          function()
            _G["pfUI_config"] = {}
            _G["pfUI_init"] = {}
            pfUI:LoadConfig()
            this:GetParent():Hide()
            pfUI.gui:Reload()
          end)
      end, true)

      CreateConfig(nil, this, T["Cache"], C.global, "profile", "button", function()
        CreateQuestionDialog(T["Do you really want to reset the Cache?"],
          function()
            _G["pfUI_playerDB"] = {}
            this:GetParent():Hide()
            pfUI.gui:Reload()
          end)
      end, true)

      CreateConfig(nil, this, T["Firstrun"], C.global, "profile", "button", function()
        _G["pfUI_init"] = {}
        pfUI.gui:Hide()
        pfUI.firstrun:NextStep()
      end, true)

      this.setup = true
    end
  end)

  -- >> Appearance
  pfUI.gui.tabs.settings.tabs.appearance = pfUI.gui.tabs.settings.tabs:CreateTabChild(T["Appearance"], true)
  pfUI.gui.tabs.settings.tabs.appearance:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Background Color"], C.appearance.border, "background", "color")
      CreateConfig(nil, this, T["Border Color"], C.appearance.border, "color", "color")
      CreateConfig(update["mapreveal"], this, T["Map Reveal Color"], C.appearance.worldmap, "mapreveal_color", "color")
      CreateConfig(nil, this) -- spacer
      CreateConfig(nil, this, T["Enable Frame Shadow"], C.appearance.border, "shadow", "checkbox")
      CreateConfig(nil, this, T["Frame Shadow Intensity"], C.appearance.border, "shadow_intensity", "dropdown", pfUI.gui.dropdowns.uf_debuff_indicator_size)
      CreateConfig(nil, this) -- spacer
      CreateConfig(nil, this, T["Global Border Size"], C.appearance.border, "default")
      CreateConfig(nil, this, T["Action Bar Border Size"], C.appearance.border, "actionbars")
      CreateConfig(nil, this, T["Unit Frame Border Size"], C.appearance.border, "unitframes")
      CreateConfig(nil, this, T["Panel Border Size"], C.appearance.border, "panels")
      CreateConfig(nil, this, T["Chat Border Size"], C.appearance.border, "chat")
      CreateConfig(nil, this, T["Bags Border Size"], C.appearance.border, "bags")
      CreateConfig(nil, this) -- spacer
      CreateConfig(nil, this, T["Enable Combat Glow Effects On Screen Edges"], C.appearance.infight, "screen", "checkbox")
      this.setup = true
    end
  end)

  -- >> Cooldown
  pfUI.gui.tabs.settings.tabs.cooldown = pfUI.gui.tabs.settings.tabs:CreateTabChild(T["Cooldown"], true)
  pfUI.gui.tabs.settings.tabs.cooldown:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Cooldown Color (Less than 3 Sec)"], C.appearance.cd, "lowcolor", "color")
      CreateConfig(nil, this, T["Cooldown Color (Seconds)"], C.appearance.cd, "normalcolor", "color")
      CreateConfig(nil, this, T["Cooldown Color (Minutes)"], C.appearance.cd, "minutecolor", "color")
      CreateConfig(nil, this, T["Cooldown Color (Hours)"], C.appearance.cd, "hourcolor", "color")
      CreateConfig(nil, this, T["Cooldown Color (Days)"], C.appearance.cd, "daycolor", "color")
      CreateConfig(nil, this, T["Cooldown Text Threshold"], C.appearance.cd, "threshold")
      CreateConfig(nil, this, T["Cooldown Text Font Size"], C.appearance.cd, "font_size")
      CreateConfig(nil, this, T["Display Debuff Durations"], C.appearance.cd, "debuffs", "checkbox")
      CreateConfig(nil, this, T["Enable Durations On Blizzard Frames"], C.appearance.cd, "blizzard", "checkbox")
      CreateConfig(nil, this, T["Enable Durations On Foreign Frames"], C.appearance.cd, "foreign", "checkbox")
      this.setup = true
    end
  end)

  -- >> GM-Mode
  pfUI.gui.tabs.settings.tabs.gm = pfUI.gui.tabs.settings.tabs:CreateTabChild(T["GM-Mode"], true)
  pfUI.gui.tabs.settings.tabs.gm:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Disable GM-Mode"], C.gm, "disable", "checkbox")
      CreateConfig(nil, this, T["Selected Core"], C.gm, "server", "dropdown", pfUI.gui.dropdowns.gmserver_text)

      this.setup = true
    end
  end)


  -- [[ UnitFrames ]]
  pfUI.gui.tabs.uf = pfUI.gui.tabs:CreateTabChild(T["Unit Frames"], nil, nil, nil, true)
  pfUI.gui.tabs.uf.tabs = CreateTabFrame(pfUI.gui.tabs.uf, "TOP", true)

  -- >> General
  pfUI.gui.tabs.uf.tabs.general = pfUI.gui.tabs.uf.tabs:CreateTabChild(T["General"], true)
  pfUI.gui.tabs.uf.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Disable pfUI Unit Frames"], C.unitframes, "disable", "checkbox")
      CreateConfig(nil, this, T["Enable Pastel Colors"], C.unitframes, "pastel", "checkbox")
      CreateConfig(nil, this, T["Enable Custom Color Health Bars"], C.unitframes, "custom", "checkbox")
      CreateConfig(nil, this, T["Custom Health Bar Color"], C.unitframes, "customcolor", "color")
      CreateConfig(nil, this, T["Enable Custom Color Health Bar Background"], C.unitframes, "custombg", "checkbox")
      CreateConfig(nil, this, T["Custom Health Bar Background Color"], C.unitframes, "custombgcolor", "color")
      CreateConfig(nil, this, T["Healthbar Animation Speed"], C.unitframes, "animation_speed", "dropdown", pfUI.gui.dropdowns.uf_animationspeed)
      CreateConfig(nil, this, T["Portrait Alpha"], C.unitframes, "portraitalpha")
      CreateConfig(nil, this, T["Always Use 2D Portraits"], C.unitframes, "always2dportrait", "checkbox")
      CreateConfig(nil, this, T["Enable 2D Portraits As Fallback"], C.unitframes, "portraittexture", "checkbox")
      CreateConfig(nil, this, T["Unit Frame Layout"], C.unitframes, "layout", "dropdown", pfUI.gui.dropdowns.uf_layout)
      CreateConfig(nil, this, T["Enable 40y-Range Check"], C.unitframes, "rangecheck", "checkbox")
      CreateConfig(nil, this, T["Range Check Interval"], C.unitframes, "rangechecki", "dropdown", pfUI.gui.dropdowns.uf_rangecheckinterval)
      CreateConfig(nil, this, T["Combopoint Size"], C.unitframes, "combosize")
      CreateConfig(nil, this, T["Abbreviate Numbers (4200 -> 4.2k)"], C.unitframes, "abbrevnum", "checkbox")
      CreateConfig(nil, this, T["Show Resting"], C.unitframes.player, "showRest", "checkbox")
      CreateConfig(nil, this, T["Enable Energy Ticks"], C.unitframes.player, "energy", "checkbox")
      this.setup = true
    end
  end)

  -- >> Target
  --  CreateConfig(nil, this, T["Enable Target Switch Animation"], C.unitframes.target, "animation", "checkbox")

  -- [[ GroupFrames ]]
  pfUI.gui.tabs.gf = pfUI.gui.tabs:CreateTabChild(T["Group Frames"], nil, nil, nil, true)
  pfUI.gui.tabs.gf.tabs = CreateTabFrame(pfUI.gui.tabs.gf, "TOP", true)

  -- >> General
  pfUI.gui.tabs.gf.tabs.general = pfUI.gui.tabs.gf.tabs:CreateTabChild(T["General"], true)
  pfUI.gui.tabs.gf.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(update["group"], this, T["Show Self in Group Frames"], C.unitframes, "selfingroup", "checkbox")
      CreateConfig(nil, this, T["Hide Group Frames While In Raid"], C.unitframes.group, "hide_in_raid", "checkbox")
      CreateConfig(nil, this, T["Use Raid Frames To Display Group Members"], C.unitframes, "raidforgroup", "checkbox")
      CreateConfig(nil, this, T["Show Hots as Buff Indicators"], C.unitframes, "show_hots", "checkbox")
      CreateConfig(nil, this, T["Show Hots of all Classes"], C.unitframes, "all_hots", "checkbox")
      CreateConfig(nil, this, T["Show Procs as Buff Indicators"], C.unitframes, "show_procs", "checkbox")
      CreateConfig(nil, this, T["Show Totems as Buff Indicators"], C.unitframes, "show_totems", "checkbox")
      CreateConfig(nil, this, T["Show Procs of all Classes"], C.unitframes, "all_procs", "checkbox")
      CreateConfig(nil, this, T["Buff Indicator Size"], C.unitframes, "indicator_size")
      CreateConfig(nil, this, T["Only Show Indicators for Dispellable Debuffs"], C.unitframes, "debuffs_class", "checkbox")
      CreateConfig(nil, this, T["Clickcast Spells"], nil, nil, "header")
      CreateConfig(nil, this, T["Click Action"], C.unitframes, "clickcast", nil, nil, nil, nil, "STRING")
      CreateConfig(nil, this, T["Shift-Click Action"], C.unitframes, "clickcast_shift", nil, nil, nil, nil, "STRING")
      CreateConfig(nil, this, T["Alt-Click Action"], C.unitframes, "clickcast_alt", nil, nil, nil, nil, "STRING")
      CreateConfig(nil, this, T["Ctrl-Click Action"], C.unitframes, "clickcast_ctrl", nil, nil, nil, nil, "STRING")
      this.setup = true
    end
  end)

  -- [[ Unit/Groupframes ]]
  -- Populate Shared UF/GF Settings
  local unitframeSettings = {
    ["uf"] = {
      --      config,     text
      [1] = { "player",   T["Player"] },
      [2] = { "target",   T["Target"] },
      [3] = { "ttarget",  T["Target-Target"]},
      [4] = { "pet",      T["Pet"] },
      [5] = { "ptarget",  T["Pet-Target"]},
      [6] = { "focus",    T["Focus"] },
    },

    ["gf"] = {
      --      config,         text
      [1] = { "raid",         T["Raid"] },
      [2] = { "group",        T["Group"] },
      [3] = { "grouptarget",  T["Group-Target"]},
      [4] = { "grouppet",     T["Group-Pet"] },
    }
  }

  -- >> Generic UnitFrame Settings
  for label in pairs(unitframeSettings) do
    for id, data in pairs(unitframeSettings[label]) do
      local c = data[1]
      local t = data[2]

      pfUI.gui.tabs[label].tabs[c] = pfUI.gui.tabs[label].tabs:CreateTabChild(t, true)
      pfUI.gui.tabs[label].tabs[c]:SetScript("OnShow", function()
        if not this.setup then
          -- link update tables
          update.ttarget     = update["targettarget"]
          update.ptarget     = update["pettarget"]
          update.grouptarget = update["group"]
          update.grouppet    = update["group"]

          -- build config entries
          CreateConfig(update[c], this, T["Display Frame"] .. ": " .. t, C.unitframes[c], "visible", "checkbox")
          CreateConfig(update[c], this, T["Enable Mouseover Tooltip"], C.unitframes[c], "showtooltip", "checkbox")
          CreateConfig(update[c], this, T["Enable Clickcast"], C.unitframes[c], "clickcast", "checkbox")
          CreateConfig(update[c], this, T["Enable Range Fading"], C.unitframes[c], "faderange", "checkbox")
          CreateConfig(update[c], this, T["Enable Aggro Glow"], C.unitframes[c], "glowaggro", "checkbox")
          CreateConfig(update[c], this, T["Enable Combat Glow"], C.unitframes[c], "glowcombat", "checkbox")
          CreateConfig(update[c], this, T["Portrait Position"], C.unitframes[c], "portrait", "dropdown", pfUI.gui.dropdowns.uf_portrait_position)
          CreateConfig(update[c], this, T["Status Bar Texture"], C.unitframes[c], "bartexture", "dropdown", pfUI.gui.dropdowns.uf_bartexture)
          CreateConfig(update[c], this, T["UnitFrame Spacing"], C.unitframes[c], "pspace")
          CreateConfig(update[c], this, T["Show PvP-Flag"], C.unitframes[c], "showPVP", "checkbox")
          CreateConfig(update[c], this, T["Display Class Buffs"], C.unitframes[c], "buff_indicator", "checkbox")

          CreateConfig(update[c], this, T["Healthbar"], nil, nil, "header")
          CreateConfig(update[c], this, T["Health Bar Width"], C.unitframes[c], "width")
          CreateConfig(update[c], this, T["Health Bar Height"], C.unitframes[c], "height")
          CreateConfig(update[c], this, T["Left Text"], C.unitframes[c], "txthpleft", "dropdown", pfUI.gui.dropdowns.uf_texts)
          CreateConfig(update[c], this, T["Center Text"], C.unitframes[c], "txthpcenter", "dropdown", pfUI.gui.dropdowns.uf_texts)
          CreateConfig(update[c], this, T["Right Text"], C.unitframes[c], "txthpright", "dropdown", pfUI.gui.dropdowns.uf_texts)
          CreateConfig(update[c], this, T["Invert Health Bar"], C.unitframes[c], "invert_healthbar", "checkbox")
          CreateConfig(update[c], this, T["Enable Vertical Health Bar"], C.unitframes[c], "verticalbar", "checkbox")

          CreateConfig(update[c], this, T["Powerbar"], nil, nil, "header")
          CreateConfig(update[c], this, T["Power Bar Height"], C.unitframes[c], "pheight")
          CreateConfig(update[c], this, T["Power Bar Width"], C.unitframes[c], "pwidth")
          CreateConfig(update[c], this, T["Left Text"], C.unitframes[c], "txtpowerleft", "dropdown", pfUI.gui.dropdowns.uf_texts)
          CreateConfig(update[c], this, T["Center Text"], C.unitframes[c], "txtpowercenter", "dropdown", pfUI.gui.dropdowns.uf_texts)
          CreateConfig(update[c], this, T["Right Text"], C.unitframes[c], "txtpowerright", "dropdown", pfUI.gui.dropdowns.uf_texts)
          CreateConfig(update[c], this, T["Power Bar Anchor"], C.unitframes[c], "panchor", "dropdown", pfUI.gui.dropdowns.uf_powerbar_position)

          CreateConfig(update[c], this, T["Combat Text"], nil, nil, "header")
          CreateConfig(update[c], this, T["Show Combat Text"], C.unitframes[c], "hitindicator", "checkbox")
          CreateConfig(update[c], this, T["Combat Text Font"], C.unitframes[c], "hitindicatorfont", "dropdown", pfUI.gui.dropdowns.fonts)
          CreateConfig(update[c], this, T["Combat Text Size"], C.unitframes[c], "hitindicatorsize")

          CreateConfig(update[c], this, T["Text Colors"], nil, nil, "header")
          CreateConfig(update[c], this, T["Enable Health Color"], C.unitframes[c], "healthcolor", "checkbox")
          CreateConfig(update[c], this, T["Enable Power Color"], C.unitframes[c], "powercolor", "checkbox")
          CreateConfig(update[c], this, T["Enable Level Color"], C.unitframes[c], "levelcolor", "checkbox")
          CreateConfig(update[c], this, T["Enable Class Color"], C.unitframes[c], "classcolor", "checkbox")

          CreateConfig(update[c], this, T["Debuff Indicators"], nil, nil, "header")
          CreateConfig(update[c], this, T["Debuff Indicator Display"], C.unitframes[c], "debuff_indicator", "dropdown", pfUI.gui.dropdowns.uf_debuff_indicator)
          CreateConfig(update[c], this, T["Debuff Indicator Position"], C.unitframes[c], "debuff_ind_pos", "dropdown", pfUI.gui.dropdowns.positions)
          CreateConfig(update[c], this, T["Debuff Indicator Size"], C.unitframes[c], "debuff_ind_size", "dropdown", pfUI.gui.dropdowns.uf_debuff_indicator_size)

          CreateConfig(update[c], this, T["Buffs"], nil, nil, "header")
          CreateConfig(update[c], this, T["Buff Position"], C.unitframes[c], "buffs", "dropdown", pfUI.gui.dropdowns.uf_buff_position)
          CreateConfig(update[c], this, T["Buff Size"], C.unitframes[c], "buffsize")
          CreateConfig(update[c], this, T["Buff Limit"], C.unitframes[c], "bufflimit")
          CreateConfig(update[c], this, T["Buffs Per Row"], C.unitframes[c], "buffperrow")

          CreateConfig(update[c], this, T["Debuffs"], nil, nil, "header")
          CreateConfig(update[c], this, T["Debuff Position"], C.unitframes[c], "debuffs", "dropdown", pfUI.gui.dropdowns.uf_buff_position)
          CreateConfig(update[c], this, T["Debuff Size"], C.unitframes[c], "debuffsize")
          CreateConfig(update[c], this, T["Debuff Limit"], C.unitframes[c], "debufflimit")
          CreateConfig(update[c], this, T["Debuffs Per Row"], C.unitframes[c], "debuffperrow")

          this.setup = true
        end
      end)
    end
  end


  -- [[ Bags & Bank ]]
  pfUI.gui.tabs.bags = pfUI.gui.tabs:CreateTabChild(T["Bags & Bank"], nil, nil, nil, true)
  pfUI.gui.tabs.bags.tabs = CreateTabFrame(pfUI.gui.tabs.bags, "TOP", true)

  -- >> General
  pfUI.gui.tabs.bags.tabs.general = pfUI.gui.tabs.bags.tabs:CreateTabChild(T["Bags & Bank"], true)
  pfUI.gui.tabs.bags.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Disable Item Quality Color For \"Common\" Items"], C.appearance.bags, "borderlimit", "checkbox")
      CreateConfig(nil, this, T["Enable Item Quality Color For Equipment Only"], C.appearance.bags, "borderonlygear", "checkbox")
      CreateConfig(nil, this, T["Highlight Unusable Items"], C.appearance.bags, "unusable", "checkbox")
      CreateConfig(nil, this, T["Unusable Item Color"], C.appearance.bags, "unusable_color", "color")
      CreateConfig(nil, this, T["Enable Movable Bags"], C.appearance.bags, "movable", "checkbox")
      CreateConfig(nil, this, T["Hide Chat When Bags Are Opened"], C.appearance.bags, "hidechat", "checkbox")
      CreateConfig(nil, this, T["Bagslots Per Row"], C.appearance.bags, "bagrowlength")
      CreateConfig(nil, this, T["Bankslots Per Row"], C.appearance.bags, "bankrowlength")
      CreateConfig(nil, this, T["Item Slot Size"], C.appearance.bags, "icon_size")
      CreateConfig(nil, this, T["Auto Sell Grey Items"], C.global, "autosell", "checkbox")
      CreateConfig(nil, this, T["Auto Repair Items"], C.global, "autorepair", "checkbox")
      this.setup = true
    end
  end)


  -- [[ Loot ]]
  pfUI.gui.tabs.loot = pfUI.gui.tabs:CreateTabChild(T["Loot"], nil, nil, nil, true)
  pfUI.gui.tabs.loot.tabs = CreateTabFrame(pfUI.gui.tabs.loot, "TOP", true)

  -- >> General
  pfUI.gui.tabs.loot.tabs.general = pfUI.gui.tabs.loot.tabs:CreateTabChild(T["Loot"], true)
  pfUI.gui.tabs.loot.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Enable Auto-Resize Loot Frame"], C.loot, "autoresize", "checkbox")
      CreateConfig(nil, this, T["Disable Loot Confirmation Dialog (Without Group)"], C.loot, "autopickup", "checkbox")
      CreateConfig(nil, this, T["Enable Loot Window On MouseCursor"], C.loot, "mousecursor", "checkbox")
      CreateConfig(nil, this, T["Enable Advanced Master Loot Menu"], C.loot, "advancedloot", "checkbox")
      CreateConfig(nil, this, T["Random Roll Announcement Rarity"], C.loot, "rollannouncequal", "dropdown", pfUI.gui.dropdowns.loot_rarity)
      CreateConfig(nil, this, T["Detailed Random Roll Announcement"], C.loot, "rollannounce", "checkbox")
      CreateConfig(nil, this, T["Use Item Rarity Color For Loot-Roll Timer"], C.loot, "raritytimer", "checkbox")
      this.setup = true
    end
  end)


  -- [[ Minimap ]]
  pfUI.gui.tabs.minimap = pfUI.gui.tabs:CreateTabChild(T["Minimap"], nil, nil, nil, true)
  pfUI.gui.tabs.minimap.tabs = CreateTabFrame(pfUI.gui.tabs.minimap, "TOP", true)

  -- >> General
  pfUI.gui.tabs.minimap.tabs.general = pfUI.gui.tabs.minimap.tabs:CreateTabChild(T["Minimap"], true)
  pfUI.gui.tabs.minimap.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Enable Zone Text On Minimap Mouseover"], C.appearance.minimap, "mouseoverzone", "checkbox")
      CreateConfig(nil, this, T["Coordinates Location"], C.appearance.minimap, "coordsloc", "dropdown", pfUI.gui.dropdowns.minimap_cords_position)
      CreateConfig(nil, this, T["Show PvP Icon"], C.unitframes.player, "showPVPMinimap", "checkbox")
      CreateConfig(nil, this, T["Show Inactive Tracking"], C.appearance.minimap, "tracking_pulse", "checkbox")
      CreateConfig(nil, this, T["Tracking Icon Size"], C.appearance.minimap, "tracking_size")
      this.setup = true
    end
  end)

  -- [[ Buffs ]]
  pfUI.gui.tabs.buffs = pfUI.gui.tabs:CreateTabChild(T["Buffs"], nil, nil, nil, true)
  pfUI.gui.tabs.buffs.tabs = CreateTabFrame(pfUI.gui.tabs.buffs, "TOP", true)

  -- >> General
  pfUI.gui.tabs.buffs.tabs.general = pfUI.gui.tabs.buffs.tabs:CreateTabChild(T["Buffs"], true)
  pfUI.gui.tabs.buffs.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(update["buff"], this, T["Enable Buff Display"], C.buffs, "buffs", "checkbox")
      CreateConfig(update["buff"], this, T["Enable Debuff Display"], C.buffs, "debuffs", "checkbox")
      CreateConfig(update["buff"], this, T["Enable Weapon Buff Display"], C.buffs, "weapons", "checkbox")
      CreateConfig(update["buff"], this, T["Seperate Weapon Buffs"], C.buffs, "separateweapons", "checkbox")
      CreateConfig(update["buff"], this, T["Buff Size"], C.buffs, "size")
      CreateConfig(update["buff"], this, T["Buff Spacing"], C.buffs, "spacing")
      CreateConfig(update["buff"], this, T["Number Of Weapon Buffs Per Row"], C.buffs, "wepbuffrowsize")
      CreateConfig(update["buff"], this, T["Number Of Buffs Per Row"], C.buffs, "buffrowsize")
      CreateConfig(update["buff"], this, T["Number Of Debuffs Per Row"], C.buffs, "debuffrowsize")
      CreateConfig(update["buff"], this, T["Show Duration Inside Buff"], C.buffs, "textinside", "checkbox")
      CreateConfig(update["buff"], this, T["Buff Font Size"], C.buffs, "fontsize")
      this.setup = true
    end
  end)

  -- >> Buff Bars
  pfUI.gui.tabs.buffs.tabs.buffbars = pfUI.gui.tabs.buffs.tabs:CreateTabChild(T["Bars"], true)
  pfUI.gui.tabs.buffs.tabs.buffbars:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(update[c], this, T["Player Buffs"], nil, nil, "header")
      CreateConfig(nil, this, T["Enable Bar"], C.buffbar.pbuff, "enable", "checkbox")
      CreateConfig(nil, this, T["Use Unit Fonts"], C.buffbar.pbuff, "use_unitfonts", "checkbox")
      CreateConfig(nil, this, T["Sort Order"], C.buffbar.pbuff, "sort", "dropdown", pfUI.gui.dropdowns.buffbarsort)
      CreateConfig(nil, this, T["Background Color"], C.buffbar.pbuff, "color", "color")
      CreateConfig(nil, this, T["Border Color"], C.buffbar.pbuff, "bordercolor", "color")
      CreateConfig(nil, this, T["Text Color"], C.buffbar.pbuff, "textcolor", "color")
      CreateConfig(nil, this, T["Automatic Background Color"], C.buffbar.pbuff, "dtypebg", "checkbox")
      CreateConfig(nil, this, T["Automatic Border Color"], C.buffbar.pbuff, "dtypeborder", "checkbox")
      CreateConfig(nil, this, T["Automatic Text Color"], C.buffbar.pbuff, "dtypetext", "checkbox")
      CreateConfig(nil, this, T["Color Buff Stacks"], C.buffbar.pbuff, "colorstacks", "checkbox")
      CreateConfig(nil, this, T["Buffbar Width"], C.buffbar.pbuff, "width")
      CreateConfig(nil, this, T["Buffbar Height"], C.buffbar.pbuff, "height")
      CreateConfig(nil, this, T["Filter Mode"], C.buffbar.pbuff, "filter", "dropdown", pfUI.gui.dropdowns.buffbarfilter)
      CreateConfig(nil, this, T["Time Threshold"], C.buffbar.pbuff, "threshold")
      CreateConfig(nil, this, T["Whitelist"], C.buffbar.pbuff, "whitelist", "list")
      CreateConfig(nil, this, T["Blacklist"], C.buffbar.pbuff, "blacklist", "list")

      CreateConfig(update[c], this, T["Player Debuffs"], nil, nil, "header")
      CreateConfig(nil, this, T["Enable Bar"], C.buffbar.pdebuff, "enable", "checkbox")
      CreateConfig(nil, this, T["Use Unit Fonts"], C.buffbar.pdebuff, "use_unitfonts", "checkbox")
      CreateConfig(nil, this, T["Sort Order"], C.buffbar.pdebuff, "sort", "dropdown", pfUI.gui.dropdowns.buffbarsort)
      CreateConfig(nil, this, T["Background Color"], C.buffbar.pdebuff, "color", "color")
      CreateConfig(nil, this, T["Border Color"], C.buffbar.pdebuff, "bordercolor", "color")
      CreateConfig(nil, this, T["Text Color"], C.buffbar.pdebuff, "textcolor", "color")
      CreateConfig(nil, this, T["Automatic Background Color"], C.buffbar.pdebuff, "dtypebg", "checkbox")
      CreateConfig(nil, this, T["Automatic Border Color"], C.buffbar.pdebuff, "dtypeborder", "checkbox")
      CreateConfig(nil, this, T["Automatic Text Color"], C.buffbar.pdebuff, "dtypetext", "checkbox")
      CreateConfig(nil, this, T["Color Debuff Stacks"], C.buffbar.pdebuff, "colorstacks", "checkbox")
      CreateConfig(nil, this, T["Buffbar Width"], C.buffbar.pdebuff, "width")
      CreateConfig(nil, this, T["Buffbar Height"], C.buffbar.pdebuff, "height")
      CreateConfig(nil, this, T["Filter Mode"], C.buffbar.pdebuff, "filter", "dropdown", pfUI.gui.dropdowns.buffbarfilter)
      CreateConfig(nil, this, T["Time Threshold"], C.buffbar.pdebuff, "threshold")
      CreateConfig(nil, this, T["Whitelist"], C.buffbar.pdebuff, "whitelist", "list")
      CreateConfig(nil, this, T["Blacklist"], C.buffbar.pdebuff, "blacklist", "list")

      CreateConfig(update[c], this, T["Target Debuffs"], nil, nil, "header")
      CreateConfig(nil, this, T["Enable Bar"], C.buffbar.tdebuff, "enable", "checkbox")
      CreateConfig(nil, this, T["Use Unit Fonts"], C.buffbar.tdebuff, "use_unitfonts", "checkbox")
      CreateConfig(nil, this, T["Sort Order"], C.buffbar.tdebuff, "sort", "dropdown", pfUI.gui.dropdowns.buffbarsort)
      CreateConfig(nil, this, T["Background Color"], C.buffbar.tdebuff, "color", "color")
      CreateConfig(nil, this, T["Border Color"], C.buffbar.tdebuff, "bordercolor", "color")
      CreateConfig(nil, this, T["Text Color"], C.buffbar.tdebuff, "textcolor", "color")
      CreateConfig(nil, this, T["Automatic Background Color"], C.buffbar.tdebuff, "dtypebg", "checkbox")
      CreateConfig(nil, this, T["Automatic Border Color"], C.buffbar.tdebuff, "dtypeborder", "checkbox")
      CreateConfig(nil, this, T["Automatic Text Color"], C.buffbar.tdebuff, "dtypetext", "checkbox")
      CreateConfig(nil, this, T["Color Debuff Stacks"], C.buffbar.tdebuff, "colorstacks", "checkbox")
      CreateConfig(nil, this, T["Buffbar Width"], C.buffbar.tdebuff, "width")
      CreateConfig(nil, this, T["Buffbar Height"], C.buffbar.tdebuff, "height")
      CreateConfig(nil, this, T["Filter Mode"], C.buffbar.tdebuff, "filter", "dropdown", pfUI.gui.dropdowns.buffbarfilter)
      CreateConfig(nil, this, T["Time Threshold"], C.buffbar.tdebuff, "threshold")
      CreateConfig(nil, this, T["Whitelist"], C.buffbar.tdebuff, "whitelist", "list")
      CreateConfig(nil, this, T["Blacklist"], C.buffbar.tdebuff, "blacklist", "list")
      this.setup = true
    end
  end)

  -- [[ Actionbar ]]
  pfUI.gui.tabs.actionbar = pfUI.gui.tabs:CreateTabChild(T["Actionbar"], nil, nil, nil, true)
  pfUI.gui.tabs.actionbar.tabs = CreateTabFrame(pfUI.gui.tabs.actionbar, "TOP", true)

  -- >> General
  pfUI.gui.tabs.actionbar.tabs.general = pfUI.gui.tabs.actionbar.tabs:CreateTabChild(T["General"], true)
  pfUI.gui.tabs.actionbar.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Icon Size"], C.bars, "icon_size")
      CreateConfig(nil, this, T["Enable Action Bar Backgrounds"], C.bars, "background", "checkbox")
      CreateConfig(MultiActionBar_UpdateGridVisibility, this, T["Always Show Action Bar Buttons"], "GVAR", "ALWAYS_SHOW_MULTIBARS", "checkbox")
      CreateConfig(nil, this, T["Enable Range Display On Hotkeys"], C.bars, "glowrange", "checkbox")
      CreateConfig(nil, this, T["Range Display Color"], C.bars, "rangecolor", "color")
      CreateConfig(nil, this, T["Show Macro Text"], C.bars, "showmacro", "checkbox")
      CreateConfig(nil, this, T["Show Hotkey Text"], C.bars, "showkeybind", "checkbox")
      CreateConfig(nil, this, T["Show Equipped Items"], C.bars, "showequipped", "checkbox")
      CreateConfig(nil, this, T["Enable Range Based Auto Paging (Hunter)"], C.bars, "hunterbar", "checkbox")
      CreateConfig(nil, this, T["Enable Action On Key Down"], C.bars, "keydown", "checkbox")
      CreateConfig(nil, this, T["Switch Bar On Meta Key Press"], C.bars, "pagemaster", "checkbox")
      CreateConfig(nil, this, T["Show Indicator For Castable Pet Actions"], C.bars, "showcastable", "checkbox")
      this.setup = true
    end
  end)

  -- >> Layout
  pfUI.gui.tabs.actionbar.tabs.layout = pfUI.gui.tabs.actionbar.tabs:CreateTabChild(T["Layout"], true)
  pfUI.gui.tabs.actionbar.tabs.layout:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(UIParent_ManageFramePositions, this, T["Enable Second Actionbar (BottomLeft)"], "GVAR", "SHOW_MULTI_ACTIONBAR_1", "checkbox")
      CreateConfig(UIParent_ManageFramePositions, this, T["Enable Left Actionbar (BottomRight)"], "GVAR", "SHOW_MULTI_ACTIONBAR_2", "checkbox")
      CreateConfig(UIParent_ManageFramePositions, this, T["Enable Right Actionbar (Right)"], "GVAR", "SHOW_MULTI_ACTIONBAR_3", "checkbox")
      CreateConfig(UIParent_ManageFramePositions, this, T["Enable Vertical Actionbar (TwoRight)"], "GVAR", "SHOW_MULTI_ACTIONBAR_4", "checkbox")

      CreateConfig(update[c], this, T["Form Factor"], nil, nil, "header")
      CreateConfig(nil, this, T["Main Actionbar (ActionMain)"], C.bars.actionmain, "formfactor", "dropdown", pfUI.gui.dropdowns.num_actionbar_buttons)
      CreateConfig(nil, this, T["Second Actionbar (BottomLeft)"], C.bars.bottomleft, "formfactor", "dropdown", pfUI.gui.dropdowns.num_actionbar_buttons)
      CreateConfig(nil, this, T["Left Actionbar (BottomRight)"], C.bars.bottomright, "formfactor", "dropdown", pfUI.gui.dropdowns.num_actionbar_buttons)
      CreateConfig(nil, this, T["Right Actionbar (Right)"], C.bars.right, "formfactor", "dropdown", pfUI.gui.dropdowns.num_actionbar_buttons)
      CreateConfig(nil, this, T["Vertical Actionbar (TwoRight)"], C.bars.tworight, "formfactor", "dropdown", pfUI.gui.dropdowns.num_actionbar_buttons)
      CreateConfig(nil, this, T["Shapeshift Bar (BarShapeShift)"], C.bars.shapeshift, "formfactor", "dropdown", pfUI.gui.dropdowns.num_shapeshift_slots)
      CreateConfig(nil, this, T["Pet Bar (BarPet)"], C.bars.pet, "formfactor", "dropdown", pfUI.gui.dropdowns.num_pet_action_slots)
      this.setup = true
    end
  end)

  -- >> Autohide
  pfUI.gui.tabs.actionbar.tabs.autohide = pfUI.gui.tabs.actionbar.tabs:CreateTabChild(T["Autohide"], true)
  pfUI.gui.tabs.actionbar.tabs.autohide:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Seconds Until Action Bars Autohide"], C.bars, "hide_time")
      CreateConfig(nil, this, T["Enable Autohide For BarActionMain"], C.bars, "hide_actionmain", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For BarBottomLeft"], C.bars, "hide_bottomleft", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For BarBottomRight"], C.bars, "hide_bottomright", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For BarRight"], C.bars, "hide_right", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For BarTwoRight"], C.bars, "hide_tworight", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For BarShapeShift"], C.bars, "hide_shapeshift", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For BarPet"], C.bars, "hide_pet", "checkbox")
      this.setup = true
    end
  end)

  -- [[ Panel ]]
  pfUI.gui.tabs.panel = pfUI.gui.tabs:CreateTabChild(T["Panel"], nil, nil, nil, true)
  pfUI.gui.tabs.panel.tabs = CreateTabFrame(pfUI.gui.tabs.panel, "TOP", true)

  -- >> General
  pfUI.gui.tabs.panel.tabs.general = pfUI.gui.tabs.panel.tabs:CreateTabChild(T["Panel"], true)
  pfUI.gui.tabs.panel.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Use Unit Fonts"], C.panel, "use_unitfonts", "checkbox")
      CreateConfig(nil, this, T["Left Panel: Left"], C.panel.left, "left", "dropdown", pfUI.gui.dropdowns.panel_values)
      CreateConfig(nil, this, T["Left Panel: Center"], C.panel.left, "center", "dropdown", pfUI.gui.dropdowns.panel_values)
      CreateConfig(nil, this, T["Left Panel: Right"], C.panel.left, "right", "dropdown", pfUI.gui.dropdowns.panel_values)
      CreateConfig(nil, this, T["Right Panel: Left"], C.panel.right, "left", "dropdown", pfUI.gui.dropdowns.panel_values)
      CreateConfig(nil, this, T["Right Panel: Center"], C.panel.right, "center", "dropdown", pfUI.gui.dropdowns.panel_values)
      CreateConfig(nil, this, T["Right Panel: Right"], C.panel.right, "right", "dropdown", pfUI.gui.dropdowns.panel_values)
      CreateConfig(nil, this, T["Other Panel: Minimap"], C.panel.other, "minimap", "dropdown", pfUI.gui.dropdowns.panel_values)
      CreateConfig(nil, this, T["Always Show Experience And Reputation Bar"], C.panel.xp, "showalways", "checkbox")
      CreateConfig(nil, this, T["Only Count Bagspace On Regular Bags"], C.panel.bag, "ignorespecial", "checkbox")
      CreateConfig(nil, this, T["Enable Micro Bar"], C.panel.micro, "enable", "checkbox")
      CreateConfig(nil, this, T["Enable 24h Clock"], C.global, "twentyfour", "checkbox")
      this.setup = true
    end
  end)

  -- >> Autohide
  pfUI.gui.tabs.panel.tabs.autohide = pfUI.gui.tabs.panel.tabs:CreateTabChild(T["Autohide"], true)
  pfUI.gui.tabs.panel.tabs.autohide:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Enable Autohide For Left Chat Panel"], C.panel, "hide_leftchat", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For Right Chat Panel"], C.panel, "hide_rightchat", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For Minimap Panel"], C.panel, "hide_minimap", "checkbox")
      CreateConfig(nil, this, T["Enable Autohide For Microbar Panel"], C.panel, "hide_microbar", "checkbox")
      this.setup = true
    end
  end)


  -- [[ Tooltip ]]
  pfUI.gui.tabs.tooltip = pfUI.gui.tabs:CreateTabChild(T["Tooltip"], nil, nil, nil, true)
  pfUI.gui.tabs.tooltip.tabs = CreateTabFrame(pfUI.gui.tabs.tooltip, "TOP", true)

  -- >> General
  pfUI.gui.tabs.tooltip.tabs.general = pfUI.gui.tabs.tooltip.tabs:CreateTabChild(T["Tooltip"], true)
  pfUI.gui.tabs.tooltip.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Tooltip Position"], C.tooltip, "position", "dropdown", pfUI.gui.dropdowns.tooltip_position)
      CreateConfig(nil, this, T["Cursor Tooltip Align"], C.tooltip, "cursoralign", "dropdown", pfUI.gui.dropdowns.tooltip_align)
      CreateConfig(nil, this, T["Cursor Tooltip Offset"], C.tooltip, "cursoroffset")
      CreateConfig(nil, this, T["Enable Extended Guild Information"], C.tooltip, "extguild", "checkbox")
      CreateConfig(nil, this, T["Custom Transparency"], C.tooltip, "alpha")
      CreateConfig(nil, this, T["Compare Item Base Stats"], C.tooltip.compare, "basestats", "checkbox")
      CreateConfig(nil, this, T["Always Show Item Comparison"], C.tooltip.compare, "showalways", "checkbox")
      CreateConfig(nil, this, T["Always Show Extended Vendor Values"], C.tooltip.vendor, "showalways", "checkbox")
      this.setup = true
    end
  end)


  -- [[ Castbar ]]
  pfUI.gui.tabs.castbar = pfUI.gui.tabs:CreateTabChild(T["Castbar"], nil, nil, nil, true)
  pfUI.gui.tabs.castbar.tabs = CreateTabFrame(pfUI.gui.tabs.castbar, "TOP", true)

  -- >> General
  pfUI.gui.tabs.castbar.tabs.general = pfUI.gui.tabs.castbar.tabs:CreateTabChild(T["Castbar"], true)
  pfUI.gui.tabs.castbar.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Use Unit Fonts"], C.castbar, "use_unitfonts", "checkbox")
      CreateConfig(nil, this, T["Casting Color"], C.appearance.castbar, "castbarcolor", "color")
      CreateConfig(nil, this, T["Channeling Color"], C.appearance.castbar, "channelcolor", "color")
      CreateConfig(nil, this, T["Disable Blizzard Castbar"], C.castbar.player, "hide_blizz", "checkbox")
      CreateConfig(nil, this, T["Disable pfUI Player Castbar"], C.castbar.player, "hide_pfui", "checkbox")
      CreateConfig(nil, this, T["Disable pfUI Target Castbar"], C.castbar.target, "hide_pfui", "checkbox")
      this.setup = true
    end
  end)


  -- [[ Chat ]]
  pfUI.gui.tabs.chat = pfUI.gui.tabs:CreateTabChild(T["Chat"], nil, nil, nil, true)
  pfUI.gui.tabs.chat.tabs = CreateTabFrame(pfUI.gui.tabs.chat, "TOP", true)

  -- >> General
  pfUI.gui.tabs.chat.tabs.general = pfUI.gui.tabs.chat.tabs:CreateTabChild(T["General"], true)
  pfUI.gui.tabs.chat.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Enable \"Loot & Spam\" Chat Window"], C.chat.right, "enable", "checkbox")
      CreateConfig(nil, this, T["Inputbox Width"], C.chat.text, "input_width")
      CreateConfig(nil, this, T["Inputbox Height"], C.chat.text, "input_height")
      CreateConfig(nil, this, T["Enable Text Shadow"], C.chat.text, "outline", "checkbox")
      CreateConfig(nil, this, T["Show Items On Mouseover"], C.chat.text, "mouseover", "checkbox")
      CreateConfig(nil, this, T["Chat Default Brackets"], C.chat.text, "bracket", nil, nil, nil, nil, "STRING")
      CreateConfig(nil, this, T["Enable Timestamps"], C.chat.text, "time", "checkbox")
      CreateConfig(nil, this, T["Timestamp Format"], C.chat.text, "timeformat", nil, nil, nil, nil, "STRING")
      CreateConfig(nil, this, T["Timestamp Brackets"], C.chat.text, "timebracket", nil, nil, nil, nil, "STRING")
      CreateConfig(nil, this, T["Timestamp Color"], C.chat.text, "timecolor", "color")
      CreateConfig(nil, this, T["Hide Channel Names"], C.chat.text, "channelnumonly", "checkbox")
      CreateConfig(nil, this, T["Generate Playerlinks"], C.chat.text, "playerlinks", "checkbox")
      CreateConfig(nil, this, T["Enable URL Detection"], C.chat.text, "detecturl", "checkbox")
      CreateConfig(nil, this, T["Enable Class Colors"], C.chat.text, "classcolor", "checkbox")
      CreateConfig(nil, this, T["Colorize Unknown Classes"], C.chat.text, "tintunknown", "checkbox")
      CreateConfig(nil, this, T["Unknown Class Color"], C.chat.text, "unknowncolor", "color")
      CreateConfig(nil, this, T["Left Chat Width"], C.chat.left, "width")
      CreateConfig(nil, this, T["Left Chat Height"], C.chat.left, "height")
      CreateConfig(nil, this, T["Right Chat Width"], C.chat.right, "width")
      CreateConfig(nil, this, T["Right Chat Height"], C.chat.right, "height")
      CreateConfig(nil, this, T["Enable Right Chat Window"], C.chat.right, "alwaysshow", "checkbox")
      CreateConfig(nil, this, T["Hide Combat Log"], C.chat.global, "combathide", "checkbox")
      CreateConfig(nil, this, T["Enable Chat Dock Background"], C.chat.global, "tabdock", "checkbox")
      CreateConfig(nil, this, T["Only Show Chat Dock On Mouseover"], C.chat.global, "tabmouse", "checkbox")
      CreateConfig(nil, this, T["Enable Chat Tab Flashing"], C.chat.global, "chatflash", "checkbox")
      CreateConfig(nil, this, T["Enable Custom Colors"], C.chat.global, "custombg", "checkbox")
      CreateConfig(nil, this, T["Chat Background Color"], C.chat.global, "background", "color")
      CreateConfig(nil, this, T["Chat Border Color"], C.chat.global, "border", "color")
      CreateConfig(nil, this, T["Enable Custom Incoming Whispers Layout"], C.chat.global, "whispermod", "checkbox")
      CreateConfig(nil, this, T["Incoming Whispers Color"], C.chat.global, "whisper", "color")
      CreateConfig(nil, this, T["Enable Sticky Chat"], C.chat.global, "sticky", "checkbox")
      CreateConfig(nil, this, T["Enable Chat Fade"], C.chat.global, "fadeout", "checkbox")
      CreateConfig(nil, this, T["Seconds Before Chat Fade"], C.chat.global, "fadetime")
      CreateConfig(nil, this, T["Mousewheel Scroll Speed"], C.chat.global, "scrollspeed")
      CreateConfig(nil, this, T["Enable Chat Bubbles"], "CVAR", "chatBubbles", "checkbox")
      CreateConfig(nil, this, T["Enable Party Chat Bubbles"], "CVAR", "chatBubblesParty", "checkbox")
      CreateConfig(nil, this, T["Chat Bubble Transparency"], C.chat.bubbles, "alpha")
      this.setup = true
    end
  end)


  -- [[ Nameplates ]]
  pfUI.gui.tabs.nameplates = pfUI.gui.tabs:CreateTabChild(T["Nameplates"], nil, nil, nil, true)
  pfUI.gui.tabs.nameplates.tabs = CreateTabFrame(pfUI.gui.tabs.nameplates, "TOP", true)

  -- General
  pfUI.gui.tabs.nameplates.tabs.general = pfUI.gui.tabs.nameplates.tabs:CreateTabChild(T["Nameplates"], true)
  pfUI.gui.tabs.nameplates.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Use Unit Fonts"], C.nameplates, "use_unitfonts", "checkbox")
      CreateConfig(nil, this, T["Enable Castbars"], C.nameplates, "showcastbar", "checkbox")
      CreateConfig(nil, this, T["Enable Spellname"], C.nameplates, "spellname", "checkbox")
      CreateConfig(nil, this, T["Enable Debuffs"], C.nameplates, "showdebuffs", "checkbox")
      CreateConfig(nil, this, T["Enable Clickthrough"], C.nameplates, "clickthrough", "checkbox")
      CreateConfig(nil, this, T["Legacy Click Handlers (Breaks Vertical Position and Overlap)"], C.nameplates, "legacy", "checkbox")
      CreateConfig(nil, this, T["Enable Overlap"], C.nameplates, "overlap", "checkbox")
      CreateConfig(nil, this, T["Enable Mouselook With Right Click"], C.nameplates, "rightclick", "checkbox")
      CreateConfig(nil, this, T["Right Click Auto Attack Threshold"], C.nameplates, "clickthreshold")
      CreateConfig(nil, this, T["Enable Class Colors On Enemies"], C.nameplates, "enemyclassc", "checkbox")
      CreateConfig(nil, this, T["Enable Class Colors On Friends"], C.nameplates, "friendclassc", "checkbox")
      CreateConfig(nil, this, T["Raid Icon Size"], C.nameplates, "raidiconsize")
      CreateConfig(nil, this, T["Show Players Only"], C.nameplates, "players", "checkbox")
      CreateConfig(nil, this, T["Hide Critters"], C.nameplates, "critters", "checkbox")
      CreateConfig(nil, this, T["Hide Totems"], C.nameplates, "totems", "checkbox")
      CreateConfig(nil, this, T["Show Health Points"], C.nameplates, "showhp", "checkbox")
      CreateConfig(nil, this, T["Vertical Position"], C.nameplates, "vpos")
      CreateConfig(nil, this, T["Nameplate Width"], C.nameplates, "width")
      CreateConfig(nil, this, T["Healthbar Height"], C.nameplates, "heighthealth")
      CreateConfig(nil, this, T["Castbar Height"], C.nameplates, "heightcast")
      CreateConfig(nil, this, T["Enable Combo Point Display"], C.nameplates, "cpdisplay", "checkbox")
      CreateConfig(nil, this, T["Highlight Target Nameplate"], C.nameplates, "targethighlight", "checkbox")
      CreateConfig(nil, this, T["Zoom Target Nameplate"], C.nameplates, "targetzoom", "checkbox")
      this.setup = true
    end
  end)


  -- [[ Thirdparty ]]
  pfUI.gui.tabs.thirdparty = pfUI.gui.tabs:CreateTabChild(T["Thirdparty"], nil, nil, nil, true)
  pfUI.gui.tabs.thirdparty.tabs = CreateTabFrame(pfUI.gui.tabs.thirdparty, "TOP", true)

  -- >> General
  pfUI.gui.tabs.thirdparty.tabs.general = pfUI.gui.tabs.thirdparty.tabs:CreateTabChild(T["Thirdparty"], true)
  pfUI.gui.tabs.thirdparty.tabs.general:SetScript("OnShow", function()
    if not this.setup then
      CreateConfig(nil, this, T["Show Meters By Default"], C.thirdparty, "showmeter", "checkbox")
      CreateConfig(nil, this, T["Use Chat Colors for Meters"], C.thirdparty, "chatbg", "checkbox")
      CreateConfig(nil, this, "DPSMate (" .. T["Skin"] .. ")", C.thirdparty.dpsmate, "skin", "checkbox")
      CreateConfig(nil, this, "DPSMate (" .. T["Dock"] .. ")", C.thirdparty.dpsmate, "dock", "checkbox")
      CreateConfig(nil, this, "SWStats (" .. T["Skin"] .. ")", C.thirdparty.swstats, "skin", "checkbox")
      CreateConfig(nil, this, "SWStats (" .. T["Dock"] .. ")", C.thirdparty.swstats, "dock", "checkbox")
      CreateConfig(nil, this, "KLH Threat Meter (" .. T["Skin"] .. ")", C.thirdparty.ktm, "skin", "checkbox")
      CreateConfig(nil, this, "KLH Threat Meter (" .. T["Dock"] .. ")", C.thirdparty.ktm, "dock", "checkbox")
      CreateConfig(nil, this, "WIM", C.thirdparty.wim, "enable", "checkbox")
      CreateConfig(nil, this, "HealComm", C.thirdparty.healcomm, "enable", "checkbox")
      CreateConfig(nil, this, "SortBags", C.thirdparty.sortbags, "enable", "checkbox")
      CreateConfig(nil, this, "MrPlow", C.thirdparty.mrplow, "enable", "checkbox")
      CreateConfig(nil, this, "FlightMap", C.thirdparty.flightmap, "enable", "checkbox")
      CreateConfig(nil, this, "AtlasLoot", C.thirdparty.atlasloot, "enable", "checkbox")
      CreateConfig(nil, this, "MyRolePlay", C.thirdparty.myroleplay, "enable", "checkbox")
      CreateConfig(nil, this, "DruidManaBar", C.thirdparty.druidmana, "enable", "checkbox")
      this.setup = true
    end
  end)


  -- [[ Core ]]
  pfUI.gui.tabs.components = pfUI.gui.tabs:CreateTabChild(T["Components"], nil, nil, nil, true)
  pfUI.gui.tabs.components.tabs = CreateTabFrame(pfUI.gui.tabs.components, "TOP", true)

  -- Modules
  pfUI.gui.tabs.components.tabs.modules = pfUI.gui.tabs.components.tabs:CreateTabChild(T["Modules"], true)
  pfUI.gui.tabs.components.tabs.modules:SetScript("OnShow", function()
    if not this.setup then
      table.sort(pfUI.modules)
      for i,m in pairs(pfUI.modules) do
        if m ~= "gui" then
          -- create disabled entry if not existing and display
          pfUI:UpdateConfig("disabled", nil, m, "0")
          CreateConfig(nil, this, T["Disable Module"] .. " " .. m, C.disabled, m, "checkbox")
        end
      end
      this.setup = true
    end
  end)

  -- Skins
  pfUI.gui.tabs.components.tabs.skins = pfUI.gui.tabs.components.tabs:CreateTabChild(T["Skins"], true)
  pfUI.gui.tabs.components.tabs.skins:SetScript("OnShow", function()
    if not this.setup then
      for i,m in pairs(pfUI.skins) do
        -- create disabled entry if not existing and display
        pfUI:UpdateConfig("disabled", nil, "skin_" .. m, "0")
        CreateConfig(nil, this, T["Disable Skin"] .. " " .. m, C.disabled, "skin_" .. m, "checkbox")
      end
      this.setup = true
    end
  end)

  -- [[ Close ]]
  pfUI.gui.tabs.close = pfUI.gui.tabs:CreateTabChild(T["Close"], nil, nil, "BOTTOM")
  pfUI.gui.tabs.close.button:SetScript("OnClick", function()
    pfUI.gui:Hide()
  end)

  -- [[ Unlock ]]
  pfUI.gui.tabs.unlock = pfUI.gui.tabs:CreateTabChild(T["Unlock"], nil, nil, "BOTTOM")
  pfUI.gui.tabs.unlock.button:SetScript("OnClick", function()
    pfUI.gui.delaySettingChanged = pfUI.gui.settingChanged
    pfUI.gui.settingChanged = nil
    pfUI.unlock:Show()
  end)

  -- [[ Hoverbind ]]
  pfUI.gui.tabs.hoverbind = pfUI.gui.tabs:CreateTabChild(T["Hoverbind"], nil, nil, "BOTTOM")
  pfUI.gui.tabs.hoverbind.button:SetScript("OnClick", function()
    if pfUI.hoverbind then
      pfUI.gui.delaySettingChanged = pfUI.gui.settingChanged
      pfUI.gui.settingChanged = nil
      pfUI.hoverbind:Show()
    end
  end)

  -- make those available to external modules
  pfUI.gui.CreateConfig = CreateConfig
  pfUI.gui.update = update
end)
