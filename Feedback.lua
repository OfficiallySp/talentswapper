--[[
  TalentSwapper — chat / UI error feedback.
]]

local F = TalentSwapper.Feedback

local function db()
  return TalentSwapper:GetDB()
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
  F.PrintOptional("|cff00ff00TalentSwapper:|r Switched to |cffffffff" .. (displayName or "?") .. "|r" .. suffix)
end

function F.OnSwapNoChange(displayName)
  F.PrintOptional("|cffaaaaaaTalentSwapper:|r Already using |cffffffff" .. (displayName or "?") .. "|r")
end

function F.OnSwapFailed(displayName, reason)
  local r = reason or "unknown"
  F.PrintOptional("|cffff4444TalentSwapper:|r Could not switch to |cffffffff" .. (displayName or "?") .. "|r (" .. r .. ")")
end

function F.OnSwapCastStarted(displayName)
  F.PrintOptional("|cffccccccTalentSwapper:|r Changing talents… |cffffffff" .. (displayName or "?") .. "|r")
end

function F.CombatBlocked()
  F.ErrorFlash("TalentSwapper: cannot change talents in combat.")
  F.PrintOptional("|cffff8800TalentSwapper:|r Wait until you are out of combat.")
end

function F.SlotEmpty(slotIndex)
  F.PrintOptional("|cffff8800TalentSwapper:|r Slot " .. tostring(slotIndex) .. " has no loadout assigned. Open /ts to assign.")
end

function F.InvalidSlot(slotIndex)
  F.PrintOptional("|cffff4444TalentSwapper:|r Invalid slot. Use 1–10.")
end

function F.Usage()
  F.PrintAlways(
    "|cff00ccffTalentSwapper|r — /ts, /talentswap, or /talentswapper\n"
      .. "  |cffffffff/ts|r — open config\n"
      .. "  |cffffffff/ts list|r — list loadouts and slots\n"
      .. "  |cffffffff/ts assign <1-10> <loadout name>|r\n"
      .. "  |cffffffff/ts clear <1-10>|r\n"
      .. "  |cffffffff/ts swap <slot or loadout name>|r"
  )
end
