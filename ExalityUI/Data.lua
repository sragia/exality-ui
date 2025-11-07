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
        self.data.profiles[name] = self.data.profiles.Base
    end
end

data.SetCurrentProfile = function(self, profile)
    self.currentProfile = profile
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

data.Save = function(self)
    ExalityUIData = self.data
    ExalityUICharData.currentProfile = self.currentProfile
end

data.SetDataByKey = function(self, key, data)
    self.data.profiles[self.currentProfile][key] = data;
end

data.GetDataByKey = function(self, key)
    return self.data.profiles[self.currentProfile][key];
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