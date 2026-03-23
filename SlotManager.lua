--[[
  TalentSwapper — slot ↔ loadout mapping and keybind handlers.
]]

local SM = TalentSwapper.SlotManager
local API = TalentSwapper.TalentAPI
local Feedback = TalentSwapper.Feedback

local function db()
  return TalentSwapper:GetDB()
end

function SM:EnsureSpecMap(specID)
  local root = db().slotMappings
  if type(root) ~= "table" then
    root = {}
    db().slotMappings = root
  end
  if not root[specID] then
    root[specID] = {}
  end
  return root[specID]
end

function SM:GetSlotConfigID(slotIndex, specID)
  specID = specID or API.GetCurrentSpecID()
  if not specID or slotIndex < 1 or slotIndex > 10 then
    return nil
  end
  local map = db().slotMappings[specID]
  if type(map) ~= "table" then
    return nil
  end
  local id = map[slotIndex]
  if type(id) ~= "number" then
    return nil
  end
  return id
end

function SM:SetSlot(slotIndex, configID, specID)
  specID = specID or API.GetCurrentSpecID()
  if not specID or slotIndex < 1 or slotIndex > 10 then
    return false
  end
  local map = self:EnsureSpecMap(specID)
  if configID == nil then
    map[slotIndex] = nil
  else
    map[slotIndex] = configID
  end
  return true
end

function SM:ClearSlot(slotIndex, specID)
  return self:SetSlot(slotIndex, nil, specID)
end

--- Apply LoadConfig and handle results / pending cast.
function SM:ExecuteSwapToConfig(configID, displayName)
  if not configID then
    Feedback.OnSwapFailed(displayName or "?", "no_config")
    return
  end

  if InCombatLockdown() then
    Feedback.CombatBlocked()
    return
  end

  local name = displayName or API.GetLoadoutName(configID) or tostring(configID)
  local result, changeError = API.LoadLoadout(configID, true)

  if result == nil then
    Feedback.OnSwapFailed(name, changeError or "api")
    return
  end

  local R = Enum.LoadConfigResult
  if result == R.Error then
    local err = changeError or "error"
    Feedback.OnSwapFailed(name, err)
    return
  end

  if result == R.NoChangesNecessary then
    Feedback.OnSwapNoChange(name)
    return
  end

  if result == R.LoadInProgress then
    TalentSwapper:SetPendingSwap(configID, name)
    Feedback.OnSwapCastStarted(name)
    return
  end

  if result == R.Ready then
    Feedback.OnSwapSuccess(name, "ready")
    return
  end

  Feedback.PrintOptional("|cffff8800TalentSwapper:|r Unexpected load result; check talent UI.")
end

function SM:OnSlotKeybind(slotIndex)
  if slotIndex < 1 or slotIndex > 10 then
    Feedback.InvalidSlot(slotIndex)
    return
  end
  local configID = self:GetSlotConfigID(slotIndex)
  if not configID then
    Feedback.SlotEmpty(slotIndex)
    return
  end
  local name = API.GetLoadoutName(configID)
  self:ExecuteSwapToConfig(configID, name)
end

local function makeSlotHandler(index)
  return function()
    SM:OnSlotKeybind(index)
  end
end

TalentSwapper_Slot1 = makeSlotHandler(1)
TalentSwapper_Slot2 = makeSlotHandler(2)
TalentSwapper_Slot3 = makeSlotHandler(3)
TalentSwapper_Slot4 = makeSlotHandler(4)
TalentSwapper_Slot5 = makeSlotHandler(5)
TalentSwapper_Slot6 = makeSlotHandler(6)
TalentSwapper_Slot7 = makeSlotHandler(7)
TalentSwapper_Slot8 = makeSlotHandler(8)
TalentSwapper_Slot9 = makeSlotHandler(9)
TalentSwapper_Slot10 = makeSlotHandler(10)
