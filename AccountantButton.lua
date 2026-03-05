function AccountantButton_OnClick()
  if AccountantFrame:IsVisible() then
    HideUIPanel(AccountantFrame)
  else
    ShowUIPanel(AccountantFrame)
  end
end

function AccountantButton_Init()
  if Accountant_SaveData[Accountant_Player]["options"].showbutton then
    AccountantButtonFrame:Show()
  else
    AccountantButtonFrame:Hide()
  end
end

function AccountantButton_Toggle()
  if AccountantButtonFrame:IsVisible() then
    AccountantButtonFrame:Hide()
    Accountant_SaveData[Accountant_Player]["options"].showbutton = false
  else
    AccountantButtonFrame:Show()
    Accountant_SaveData[Accountant_Player]["options"].showbutton = true
  end
end

function AccountantButton_UpdatePosition()
  local pos = Accountant_SaveData[Accountant_Player]["options"].buttonpos
  AccountantButtonFrame:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 55 - (75 * cos(pos)), (75 * sin(pos)) - 55)
end

-- ---------------------------------------------------------------------------
-- Frame Creation
-- Replaces AccountantButton.xml.
-- ---------------------------------------------------------------------------

local function AccountantButton_CreateFrames()
  local f = CreateFrame("Frame", "AccountantButtonFrame", Minimap)
  f:SetWidth(32)
  f:SetHeight(32)
  f:SetPoint("TOPLEFT", Minimap, "RIGHT", 2, 0)
  f:EnableMouse(true)
  f:SetFrameStrata("LOW")
  f:Show()

  local btn = CreateFrame("Button", "AccountantButton", f)
  btn:SetWidth(32)
  btn:SetHeight(32)
  btn:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  btn:SetNormalTexture("Interface\\AddOns\\Accountant\\img\\AccountantButton-Up")
  btn:SetPushedTexture("Interface\\AddOns\\Accountant\\img\\AccountantButton-Down")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  btn:GetHighlightTexture():SetBlendMode("ADD")
  btn:SetScript("OnClick", function()
    AccountantButton_OnClick()
  end)
end

AccountantButton_CreateFrames()
