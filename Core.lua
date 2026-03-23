--[[
  TalentSwap — core: namespace, saved variables, event frame, binding labels.
]]

TalentSwap = TalentSwap or {}
TalentSwap.addonName = "TalentSwap"
TalentSwap.version = "1.0.0"

TalentSwap.TalentAPI = TalentSwap.TalentAPI or {}
TalentSwap.Feedback = TalentSwap.Feedback or {}
TalentSwap.SlotManager = TalentSwap.SlotManager or {}
TalentSwap.UI = TalentSwap.UI or {}

--- Key binding UI strings (must exist before Bindings.xml resolves)
BINDING_HEADER_TALENTSWAP = "TalentSwap"
BINDING_NAME_TALENTSWAP_SLOT1 = "Talent loadout slot 1"
BINDING_NAME_TALENTSWAP_SLOT2 = "Talent loadout slot 2"
BINDING_NAME_TALENTSWAP_SLOT3 = "Talent loadout slot 3"
BINDING_NAME_TALENTSWAP_SLOT4 = "Talent loadout slot 4"
BINDING_NAME_TALENTSWAP_SLOT5 = "Talent loadout slot 5"

--- Pending swap after LoadInProgress (cast bar)
TalentSwap.pendingSwap = nil

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

function TalentSwap:GetDB()
  return TalentSwapDB
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

--- ADDON_LOADED passes the AddOns folder name; casing may differ (e.g. talentswap vs TalentSwap).
local function addonFolderMatches(addonName)
  if type(addonName) ~= "string" then
    return false
  end
  return string.lower(addonName) == string.lower(TalentSwap.addonName)
end

local function onAddonLoaded(addonName)
  if not addonFolderMatches(addonName) then
    return
  end
  TalentSwapDB = TalentSwapDB or defaultDB()
  mergeDefaults(TalentSwapDB)
end

local function onPlayerLogin()
  -- Ensure DB exists if ADDON_LOADED name check failed or load order differed
  TalentSwapDB = TalentSwapDB or defaultDB()
  mergeDefaults(TalentSwapDB)
  if TalentSwap.UI and TalentSwap.UI.OnPlayerLogin then
    TalentSwap.UI:OnPlayerLogin()
  end
end

local function onTraitConfigUpdated()
  if not TalentSwap.pendingSwap then
    return
  end
  local pending = TalentSwap.pendingSwap
  TalentSwap.pendingSwap = nil
  local currentId = TalentSwap.TalentAPI.GetCurrentLoadoutConfigID()
  if currentId == pending.configID then
    TalentSwap.Feedback.OnSwapSuccess(pending.name, "cast")
  else
    TalentSwap.Feedback.PrintOptional("TalentSwap: loadout update finished; confirm in the talent UI if needed.")
  end
end

local function onConfigCommitFailed()
  if not TalentSwap.pendingSwap then
    return
  end
  local pending = TalentSwap.pendingSwap
  TalentSwap.pendingSwap = nil
  TalentSwap.Feedback.OnSwapFailed(pending.name, "commit_failed")
end

local function onActiveTalentGroupChanged()
  if TalentSwap.UI and TalentSwap.UI.RefreshIfVisible then
    TalentSwap.UI:RefreshIfVisible()
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

function TalentSwap:SetPendingSwap(configID, displayName)
  self.pendingSwap = {
    configID = configID,
    name = displayName,
  }
end

function TalentSwap:ClearPendingSwap()
  self.pendingSwap = nil
end
