--[[
  TalentSwap — config panel and slash commands.
]]

local UI = TalentSwap.UI
local API = TalentSwap.TalentAPI
local SM = TalentSwap.SlotManager
local Feedback = TalentSwap.Feedback

local NOT_BOUND = "(not bound)"

local mainFrame
local specText
local activeText
local rowControls

local function getKeybindDisplay(slotIndex)
  local bindName = "TALENTSWAP_SLOT" .. tostring(slotIndex)
  local key = GetBindingKey(bindName)
  if not key or key == "" then
    return NOT_BOUND
  end
  return GetBindingText(key, "KEY_", true)
end

local function refreshHeader()
  if not mainFrame then
    return
  end
  local specID = API.GetCurrentSpecID()
  local specIndex = GetSpecialization()
  local specName = specIndex and select(2, GetSpecializationInfo(specIndex)) or "?"
  specText:SetText("Specialization: |cffffffff" .. (specName or "?") .. "|r  (id " .. tostring(specID or "?") .. ")")
  local curId = API.GetCurrentLoadoutConfigID(specID)
  local curName = curId and API.GetLoadoutName(curId) or "?"
  activeText:SetText("Active loadout: |cffffffff" .. curName .. "|r")
end

local function setDropdownToSlot(dropdown, slotIndex)
  local specID = API.GetCurrentSpecID()
  local configID = SM:GetSlotConfigID(slotIndex, specID)
  if not configID then
    UIDropDownMenu_SetText(dropdown, "(none)")
    return
  end
  local name = API.GetLoadoutName(configID)
  UIDropDownMenu_SetText(dropdown, name or ("#" .. tostring(configID)))
end

local function buildDropdownInit(slotIndex)
  return function(_, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "(none)"
    info.notCheckable = true
    info.func = function()
      SM:ClearSlot(slotIndex, API.GetCurrentSpecID())
      setDropdownToSlot(_G["TalentSwapDropDown" .. slotIndex], slotIndex)
    end
    UIDropDownMenu_AddButton(info, level)

    local loadouts = API.GetLoadouts()
    for _, lo in ipairs(loadouts) do
      info = UIDropDownMenu_CreateInfo()
      info.text = lo.name
      info.notCheckable = true
      info.func = function()
        SM:SetSlot(slotIndex, lo.configID, API.GetCurrentSpecID())
        setDropdownToSlot(_G["TalentSwapDropDown" .. slotIndex], slotIndex)
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end
end

local function refreshRows()
  if not rowControls then
    return
  end
  refreshHeader()
  for i = 1, 10 do
    local row = rowControls[i]
    if row then
      UIDropDownMenu_Initialize(row.dropdown, buildDropdownInit(i))
      setDropdownToSlot(row.dropdown, i)
      row.keyText:SetText("Key: |cffffffff" .. getKeybindDisplay(i) .. "|r")
    end
  end
end

function UI:RefreshIfVisible()
  if mainFrame and mainFrame:IsShown() then
    refreshRows()
  end
end

local function createMainFrame()
  local f = CreateFrame("Frame", "TalentSwapConfigFrame", UIParent, "BackdropTemplate")
  f:SetSize(520, 420)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  f:SetBackdropColor(0, 0, 0, 0.92)
  f:Hide()

  tinsert(UISpecialFrames, f:GetName())

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  title:SetText("TalentSwap")

  specText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  specText:SetPoint("TOPLEFT", 24, -44)
  specText:SetWidth(480)
  specText:SetJustifyH("LEFT")

  activeText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  activeText:SetPoint("TOPLEFT", specText, "BOTTOMLEFT", 0, -6)
  activeText:SetWidth(480)
  activeText:SetJustifyH("LEFT")

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", activeText, "BOTTOMLEFT", 0, -8)
  hint:SetWidth(480)
  hint:SetJustifyH("LEFT")
  hint:SetText("Assign a saved talent loadout to each slot, then bind keys in Esc → Options → Key Bindings → Addons → TalentSwap.")

  rowControls = {}
  local y = -110
  for i = 1, 10 do
    local slotIndex = i
    local row = CreateFrame("Frame", nil, f)
    row:SetSize(480, 28)
    row:SetPoint("TOPLEFT", 20, y)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 0, 0)
    label:SetText("Slot " .. slotIndex)

    local dd = CreateFrame("Frame", "TalentSwapDropDown" .. slotIndex, row, "UIDropDownMenuTemplate")
    dd:SetPoint("LEFT", label, "RIGHT", 12, -2)
    UIDropDownMenu_SetWidth(dd, 220)
    UIDropDownMenu_Initialize(dd, buildDropdownInit(slotIndex))

    local keyText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    keyText:SetPoint("LEFT", dd, "RIGHT", 12, 2)
    keyText:SetWidth(120)
    keyText:SetJustifyH("LEFT")

    local swapBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    swapBtn:SetSize(70, 22)
    swapBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    swapBtn:SetText("Swap")
    swapBtn:SetScript("OnClick", function()
      SM:OnSlotKeybind(slotIndex)
    end)

    row.dropdown = dd
    row.keyText = keyText
    rowControls[slotIndex] = row
    y = y - 30
  end

  local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  closeBtn:SetSize(100, 24)
  closeBtn:SetPoint("BOTTOM", 0, 16)
  closeBtn:SetText(CLOSE)
  closeBtn:SetScript("OnClick", function()
    f:Hide()
  end)

  mainFrame = f
end

function UI:ShowConfig()
  if not mainFrame then
    createMainFrame()
  end
  refreshRows()
  mainFrame:Show()
end

function UI:ToggleConfig()
  if not mainFrame then
    self:ShowConfig()
    return
  end
  if mainFrame:IsShown() then
    mainFrame:Hide()
  else
    self:ShowConfig()
  end
end

function UI:OnPlayerLogin()
  SLASH_TALENTSWAP1 = "/talentswap"
  SLASH_TALENTSWAP2 = "/ts"
  SlashCmdList["TALENTSWAP"] = function(msg)
    UI:HandleSlash(strtrim(msg or ""))
  end
end

local function printList()
  local loadouts = API.GetLoadouts()
  Feedback.PrintAlways("|cff00ccffTalentSwap|r — loadouts for this spec:")
  if #loadouts == 0 then
    Feedback.PrintAlways("  (none — save loadouts in the talent UI first)")
  else
    for _, lo in ipairs(loadouts) do
      Feedback.PrintAlways("  |cffffffff" .. lo.name .. "|r  (id " .. tostring(lo.configID) .. ")")
    end
  end
  Feedback.PrintAlways("Slot assignments:")
  for i = 1, 10 do
    local id = SM:GetSlotConfigID(i)
    if id then
      local n = API.GetLoadoutName(id) or "?"
      Feedback.PrintAlways("  Slot " .. i .. ": |cffffffff" .. n .. "|r")
    else
      Feedback.PrintAlways("  Slot " .. i .. ": |cff888888(empty)|r")
    end
  end
end

function UI:HandleSlash(msg)
  if msg == "" then
    self:ShowConfig()
    return
  end

  local cmd, rest = msg:match("^(%S+)%s*(.*)$")
  cmd = cmd and string.lower(cmd) or ""

  if cmd == "list" then
    printList()
    return
  end

  if cmd == "help" or cmd == "?" then
    Feedback.Usage()
    return
  end

  if cmd == "clear" then
    local slot = tonumber(rest)
    if not slot or slot < 1 or slot > 10 then
      Feedback.PrintAlways("|cffff4444TalentSwap:|r Usage: /ts clear <1-10>")
      return
    end
    SM:ClearSlot(slot, API.GetCurrentSpecID())
    Feedback.PrintAlways("|cff00ff00TalentSwap:|r Cleared slot " .. tostring(slot) .. ".")
    self:RefreshIfVisible()
    return
  end

  if cmd == "assign" then
    local slot, name = rest:match("^(%d+)%s+(.+)$")
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > 10 or not name or name == "" then
      Feedback.PrintAlways("|cffff4444TalentSwap:|r Usage: /ts assign <1-10> <loadout name>")
      return
    end
    name = strtrim(name)
    local configID, resolved = API.FindLoadoutByName(name)
    if not configID then
      Feedback.PrintAlways("|cffff4444TalentSwap:|r No loadout named \"" .. name .. "\".")
      return
    end
    SM:SetSlot(slot, configID, API.GetCurrentSpecID())
    Feedback.PrintAlways("|cff00ff00TalentSwap:|r Slot " .. tostring(slot) .. " → |cffffffff" .. resolved .. "|r")
    self:RefreshIfVisible()
    return
  end

  if cmd == "swap" then
    local token = strtrim(rest)
    if token == "" then
      Feedback.PrintAlways("|cffff4444TalentSwap:|r Usage: /ts swap <1-10 or loadout name>")
      return
    end
    local asNum = tonumber(token)
    if asNum and asNum >= 1 and asNum <= 10 then
      SM:OnSlotKeybind(asNum)
      return
    end
    local configID, resolved = API.FindLoadoutByName(token)
    if configID then
      SM:ExecuteSwapToConfig(configID, resolved)
      return
    end
    Feedback.PrintAlways("|cffff4444TalentSwap:|r No slot or loadout matched \"" .. token .. "\".")
    return
  end

  Feedback.PrintAlways("|cffff4444TalentSwap:|r Unknown command. Try |cffffffff/ts help|r")
end
