--[[
  TalentSwapper — core: namespace, saved variables, event frame, binding labels.
]]

TalentSwapper = TalentSwapper or {}
TalentSwapper.addonName = "TalentSwapper"
TalentSwapper.version = "1.0.0"

TalentSwapper.TalentAPI = TalentSwapper.TalentAPI or {}
TalentSwapper.Feedback = TalentSwapper.Feedback or {}
TalentSwapper.SlotManager = TalentSwapper.SlotManager or {}
TalentSwapper.UI = TalentSwapper.UI or {}

--- Key binding UI strings (must exist before Bindings.xml resolves)
BINDING_HEADER_TALENTSWAPPER = "TalentSwapper"
BINDING_NAME_TALENTSWAPPER_SLOT1 = "Talent loadout slot 1"
BINDING_NAME_TALENTSWAPPER_SLOT2 = "Talent loadout slot 2"
BINDING_NAME_TALENTSWAPPER_SLOT3 = "Talent loadout slot 3"
BINDING_NAME_TALENTSWAPPER_SLOT4 = "Talent loadout slot 4"
BINDING_NAME_TALENTSWAPPER_SLOT5 = "Talent loadout slot 5"

--- Pending swap after LoadInProgress (cast bar)
TalentSwapper.pendingSwap = nil

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("CONFIG_COMMIT_FAILED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

local function defaultDB()
  return {
    slotMappings = {},
    showToast = true,
    chatMessages = true,
  }
end

function TalentSwapper:GetDB()
  return TalentSwapperDB
end

local function mergeDefaults(db)
  if type(db) ~= "table" then
    return
  end
  local d = defaultDB()
  if type(db.slotMappings) ~= "table" then
    db.slotMappings = d.slotMappings
  end
  if db.showToast == nil then
    db.showToast = d.showToast
  end
  if db.chatMessages == nil then
    db.chatMessages = d.chatMessages
  end
end

--- ADDON_LOADED passes the AddOns folder name; casing may differ (e.g. talentswapper vs TalentSwapper).
local function addonFolderMatches(addonName)
  if type(addonName) ~= "string" then
    return false
  end
  return string.lower(addonName) == string.lower(TalentSwapper.addonName)
end

local function onAddonLoaded(addonName)
  if not addonFolderMatches(addonName) then
    return
  end
  if not TalentSwapperDB and TalentSwapDB and type(TalentSwapDB) == "table" then
    TalentSwapperDB = CopyTable(TalentSwapDB)
  end
  TalentSwapperDB = TalentSwapperDB or defaultDB()
  mergeDefaults(TalentSwapperDB)
end

local function onPlayerLogin()
  -- Ensure DB exists if ADDON_LOADED name check failed or load order differed
  if not TalentSwapperDB and TalentSwapDB and type(TalentSwapDB) == "table" then
    TalentSwapperDB = CopyTable(TalentSwapDB)
  end
  TalentSwapperDB = TalentSwapperDB or defaultDB()
  mergeDefaults(TalentSwapperDB)
  if TalentSwapper.UI and TalentSwapper.UI.OnPlayerLogin then
    TalentSwapper.UI:OnPlayerLogin()
  end
end

local function onTraitConfigUpdated()
  if not TalentSwapper.pendingSwap then
    return
  end
  local pending = TalentSwapper.pendingSwap
  TalentSwapper.pendingSwap = nil
  local currentId = TalentSwapper.TalentAPI.GetCurrentLoadoutConfigID()
  if currentId == pending.configID then
    TalentSwapper.Feedback.OnSwapSuccess(pending.name, "cast")
  else
    TalentSwapper.Feedback.PrintOptional("TalentSwapper: loadout update finished; confirm in the talent UI if needed.")
  end
end

local function onConfigCommitFailed()
  if not TalentSwapper.pendingSwap then
    return
  end
  local pending = TalentSwapper.pendingSwap
  TalentSwapper.pendingSwap = nil
  TalentSwapper.Feedback.OnSwapFailed(pending.name, "commit_failed")
end

local function onActiveTalentGroupChanged()
  if TalentSwapper.UI and TalentSwapper.UI.RefreshIfVisible then
    TalentSwapper.UI:RefreshIfVisible()
  end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    onAddonLoaded(...)
  elseif event == "PLAYER_LOGIN" then
    onPlayerLogin()
  elseif event == "TRAIT_CONFIG_UPDATED" then
    onTraitConfigUpdated()
  elseif event == "CONFIG_COMMIT_FAILED" then
    onConfigCommitFailed()
  elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
    onActiveTalentGroupChanged()
  end
end)

function TalentSwapper:SetPendingSwap(configID, displayName)
  self.pendingSwap = {
    configID = configID,
    name = displayName,
  }
end

function TalentSwapper:ClearPendingSwap()
  self.pendingSwap = nil
end
