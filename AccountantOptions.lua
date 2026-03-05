function AccountantOptions_Toggle()
  if AccountantOptionsFrame:IsVisible() then
    AccountantOptionsFrame:Hide()
  else
    AccountantOptionsFrame:Show()
  end
end

function AccountantOptions_OnLoad()
  UIPanelWindows["AccountantOptionsFrame"] = { area = "center", pushable = 0 }
end

function AccountantOptions_OnShow()
  AccountantOptionsFrameToggleButtonText:SetText(ACCLOC_MINIBUT)
  AccountantSliderButtonPosText:SetText(ACCLOC_BUTPOS)
  AccountantOptionsFrameWeekLabel:SetText(ACCLOC_STARTWEEK)

  AccountantOptionsFrameToggleButton:SetChecked(Accountant_SaveData[Accountant_Player]["options"].showbutton)
  AccountantSliderButtonPos:SetValue(Accountant_SaveData[Accountant_Player]["options"].buttonpos)
  UIDropDownMenu_Initialize(AccountantOptionsFrameWeek, AccountantOptionsFrameWeek_Init)
  UIDropDownMenu_SetSelectedID(AccountantOptionsFrameWeek, Accountant_SaveData[Accountant_Player]["options"].weekstart)
end

function AccountantOptions_OnHide()
  if MYADDONS_ACTIVE_OPTIONSFRAME == AccountantOptionsFrame then
    ShowUIPanel(myAddOnsFrame)
  end
end

function AccountantOptionsFrameWeek_Init()
  local dayList = {
    ACCLOC_WD_SUN,
    ACCLOC_WD_MON,
    ACCLOC_WD_TUE,
    ACCLOC_WD_WED,
    ACCLOC_WD_THU,
    ACCLOC_WD_FRI,
    ACCLOC_WD_SAT,
  }
  for i = 1, table.getn(dayList), 1 do
    local info = {}
    info.text = dayList[i]
    info.func = function()
      AccountantOptionsFrameWeek_OnClick(this)
    end

    UIDropDownMenu_AddButton(info)
  end
end

function AccountantOptionsFrameWeek_OnClick(item)
  UIDropDownMenu_SetSelectedID(AccountantOptionsFrameWeek, item:GetID())
  Accountant_SaveData[Accountant_Player]["options"].weekstart = item:GetID()
end

-- ---------------------------------------------------------------------------
-- Frame Creation
-- Replaces AccountantOptions.xml.
-- ---------------------------------------------------------------------------

local function AccountantOptions_CreateFrames()
  local f = CreateFrame("Frame", "AccountantOptionsFrame", UIParent)
  f:SetWidth(300)
  f:SetHeight(200)
  f:SetPoint("CENTER", UIParent, "CENTER")
  f:SetToplevel(true)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:EnableKeyboard(true)
  f:Hide()

  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })

  f:SetScript("OnShow", function()
    AccountantOptions_OnShow()
  end)
  f:SetScript("OnHide", function()
    AccountantOptions_OnHide()
  end)

  -- Header texture
  local header = f:CreateTexture("AccountantOptionsFrameHeader", "ARTWORK")
  header:SetWidth(256)
  header:SetHeight(64)
  header:SetPoint("TOP", f, "TOP", 0, 12)
  header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")

  -- Title text
  local titleText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  titleText:SetPoint("TOP", header, "TOP", 0, -14)
  titleText:SetText(ACCLOC_OPTS)

  -- Minimap button toggle checkbox
  local toggleBtn = CreateFrame("CheckButton", "AccountantOptionsFrameToggleButton", f, "OptionsCheckButtonTemplate")
  toggleBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 40, -30)
  toggleBtn:SetScript("OnClick", function()
    AccountantButton_Toggle()
  end)

  -- The label for the checkbox is created by OptionsCheckButtonTemplate as <buttonName>Text
  local toggleText = getglobal("AccountantOptionsFrameToggleButtonText")
  if toggleText then
    toggleText:SetText(ACCLOC_MINIBUT)
  end

  -- Minimap button position slider
  local slider = CreateFrame("Slider", "AccountantSliderButtonPos", f, "OptionsSliderTemplate")
  slider:SetWidth(220)
  slider:SetHeight(16)
  slider:SetPoint("TOP", f, "TOP", 0, -75)
  slider:SetMinMaxValues(0, 360)
  slider:SetValueStep(1)

  -- Clear the low/high labels that OptionsSliderTemplate adds
  getglobal("AccountantSliderButtonPosLow"):SetText("")
  getglobal("AccountantSliderButtonPosHigh"):SetText("")

  local sliderText = getglobal("AccountantSliderButtonPosText")
  if sliderText then
    sliderText:SetText(ACCLOC_BUTPOS)
  end

  slider:SetScript("OnValueChanged", function()
    Accountant_SaveData[UnitName("player")]["options"].buttonpos = AccountantSliderButtonPos:GetValue()
    AccountantButton_UpdatePosition()
  end)

  -- Week start dropdown
  local weekDropdown = CreateFrame("Frame", "AccountantOptionsFrameWeek", f, "UIDropDownMenuTemplate")
  weekDropdown:SetPoint("TOP", f, "TOPLEFT", 87, -110)
  weekDropdown:EnableMouse(true)

  -- Week dropdown label, named so AccountantOptions_OnShow can find it
  local weekLabel =
    weekDropdown:CreateFontString("AccountantOptionsFrameWeekLabel", "BACKGROUND", "GameFontNormalSmall")
  weekLabel:SetPoint("BOTTOMLEFT", weekDropdown, "TOPLEFT", 21, 0)
  weekLabel:SetText(ACCLOC_STARTWEEK)

  UIDropDownMenu_Initialize(weekDropdown, AccountantOptionsFrameWeek_Init)

  -- Done button
  local doneBtn = CreateFrame("Button", "AccountantOptionsFrameDone", f, "OptionsButtonTemplate")
  doneBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
  doneBtn:SetText(ACCLOC_DONE)
  doneBtn:SetScript("OnClick", function()
    AccountantOptions_Toggle()
  end)
end

AccountantOptions_CreateFrames()
