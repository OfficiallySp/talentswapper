--[[
  TalentSwap — chat / UI error feedback.
]]

local F = TalentSwap.Feedback

local function db()
  return TalentSwap:GetDB()
end

function F.PrintOptional(msg)
  if db().chatMessages then
    print(msg)
  end
end

function F.PrintAlways(msg)
  print(msg)
end

function F.ErrorFlash(text)
  UIErrorsFrame:AddMessage(text, 1.0, 0.1, 0.1, 1.0)
end

function F.OnSwapSuccess(displayName, source)
  local suffix = ""
  if source == "cast" then
    suffix = " (after cast)"
  end
  F.PrintOptional("|cff00ff00TalentSwap:|r Switched to |cffffffff" .. (displayName or "?") .. "|r" .. suffix)
end

function F.OnSwapNoChange(displayName)
  F.PrintOptional("|cffaaaaaaTalentSwap:|r Already using |cffffffff" .. (displayName or "?") .. "|r")
end

function F.OnSwapFailed(displayName, reason)
  local r = reason or "unknown"
  F.PrintOptional("|cffff4444TalentSwap:|r Could not switch to |cffffffff" .. (displayName or "?") .. "|r (" .. r .. ")")
end

function F.OnSwapCastStarted(displayName)
  F.PrintOptional("|cffccccccTalentSwap:|r Changing talents… |cffffffff" .. (displayName or "?") .. "|r")
end

function F.CombatBlocked()
  F.ErrorFlash("TalentSwap: cannot change talents in combat.")
  F.PrintOptional("|cffff8800TalentSwap:|r Wait until you are out of combat.")
end

function F.SlotEmpty(slotIndex)
  F.PrintOptional("|cffff8800TalentSwap:|r Slot " .. tostring(slotIndex) .. " has no loadout assigned. Open /ts to assign.")
end

function F.InvalidSlot(slotIndex)
  F.PrintOptional("|cffff4444TalentSwap:|r Invalid slot. Use 1–10.")
end

function F.Usage()
  F.PrintAlways(
    "|cff00ccffTalentSwap|r — /ts or /talentswap\n"
      .. "  |cffffffff/ts|r — open config\n"
      .. "  |cffffffff/ts list|r — list loadouts and slots\n"
      .. "  |cffffffff/ts assign <1-10> <loadout name>|r\n"
      .. "  |cffffffff/ts clear <1-10>|r\n"
      .. "  |cffffffff/ts swap <slot or loadout name>|r"
  )
end
