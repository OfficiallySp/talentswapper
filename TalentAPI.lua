--[[
  TalentSwap — wrappers for C_ClassTalents / C_Traits.
]]

local API = TalentSwap.TalentAPI

function API.GetCurrentSpecID()
  local specIndex = GetSpecialization()
  if not specIndex then
    return nil
  end
  local specID = select(1, GetSpecializationInfo(specIndex))
  return specID
end

--- @return table<number, number> configIDs indexed 1..n
function API.GetConfigIDsForSpec(specID)
  specID = specID or API.GetCurrentSpecID()
  if not specID then
    return {}
  end
  local ids = C_ClassTalents.GetConfigIDsBySpecID(specID)
  if type(ids) ~= "table" then
    return {}
  end
  return ids
end

--- @return { { configID = number, name = string } }
function API.GetLoadouts(specID)
  specID = specID or API.GetCurrentSpecID()
  local list = {}
  local ids = API.GetConfigIDsForSpec(specID)
  for _, configID in ipairs(ids) do
    local name = API.GetLoadoutName(configID)
    if name then
      table.insert(list, {
        configID = configID,
        name = name,
      })
    end
  end
  table.sort(list, function(a, b)
    return string.lower(a.name) < string.lower(b.name)
  end)
  return list
end

function API.GetLoadoutName(configID)
  if not configID then
    return nil
  end
  local info = C_Traits.GetConfigInfo(configID)
  if not info or not info.name then
    return nil
  end
  return info.name
end

function API.GetCurrentLoadoutConfigID(specID)
  specID = specID or API.GetCurrentSpecID()
  if not specID then
    return nil
  end
  local id = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
  return id
end

--- @return Enum.LoadConfigResult|nil, string|nil, table|nil
function API.LoadLoadout(configID, autoApply)
  if not configID then
    return nil, "no_config", nil
  end
  autoApply = autoApply ~= false
  return C_ClassTalents.LoadConfig(configID, autoApply)
end

--- Find loadout by exact name (case-sensitive per Blizzard) or trimmed case-insensitive fallback.
function API.FindLoadoutByName(name, specID)
  if not name or name == "" then
    return nil
  end
  local loadouts = API.GetLoadouts(specID)
  for _, entry in ipairs(loadouts) do
    if entry.name == name then
      return entry.configID, entry.name
    end
  end
  local lower = string.lower(name)
  for _, entry in ipairs(loadouts) do
    if string.lower(entry.name) == lower then
      return entry.configID, entry.name
    end
  end
  return nil
end
