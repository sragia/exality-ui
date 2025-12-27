---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

data.currentProfile = 'Base'

data.data = {
    profiles = {
        Base = {
            showMinimap = true
        }
    }
}

data.Init = function(self)
    if (ExalityUIData) then
        self.data = ExalityUIData
    end
    if (ExalityUICharData) then
        self.currentProfile = ExalityUICharData.currentProfile
    else
        ExalityUICharData = {
            currentProfile = self.currentProfile
        }
    end
end

data.CreateProfile = function(self, name, copyFromCurrent)
    if (copyFromCurrent) then
        self.data.profiles[name] = self.data.profiles[self.currentProfile]
    else
        self.data.profiles[name] = {
            showMinimap = true
        }
    end
end

data.CreateProfileFromData = function(self, name, data)
    self.data.profiles[name] = data
end

data.SetCurrentProfile = function(self, profile)
    self.currentProfile = profile
end

data.GetDuplicateProfileName = function(self, name)
    local baseName = name
    local indx = 1
    while (self:HasProfile(name)) do
        name = baseName .. ' (' .. indx .. ')'
        indx = indx + 1
    end
    return name
end

data.HasProfile = function(self, name)
    return self.data.profiles[name] ~= nil
end

data.GetCurrentProfile = function(self)
    return self.currentProfile
end

data.GetAllProfiles = function(self)
    local profiles = {}
    for name, _ in pairs(self.data.profiles) do
        profiles[name] = name
    end
    return profiles
end

data.GetData = function(self)
    return self.data.profiles[self.currentProfile]
end

data.Save = function(self)
    ExalityUIData = self.data
    ExalityUICharData.currentProfile = self.currentProfile
end

data.SetDataByKey = function(self, key, data)
    self.data.profiles[self.currentProfile][key] = data;
end

data.GetDataByKey = function(self, key)
    self.data.profiles[self.currentProfile] = self.data.profiles[self.currentProfile] or {}
    return self.data.profiles[self.currentProfile][key] or {};
end

data.AddDataToKey = function(self, key, data)
    self.data.profiles[self.currentProfile][key] = self.data.profiles[self.currentProfile][key] or {}
    table.insert(self.data.profiles[self.currentProfile][key], data)
end

data.UpdateDefaults = function(self, defaults)
    for key, value in pairs(defaults) do
        if (self.data.profiles[self.currentProfile][key] == nil) then
            self.data.profiles[self.currentProfile][key] = value
        end
    end
end
