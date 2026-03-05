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
