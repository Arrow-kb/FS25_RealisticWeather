-- WeatherInstance.lua (RW_WeatherInstance)
-- Extension for FS25_RealisticWeather custom WeatherInstance fields:
--   isBlizzard   -> true if this weather slot is a blizzard event
--   isDraught    -> true if this weather slot is a drought event
--   snowForecast -> snow forecast in cm (float, nil when not used)
--
-- Fix applied:
--   The original file defined functions with "function RW_WeatherInstance:..."
--   before RW_WeatherInstance existed. That causes:
--   "attempt to index nil with 'saveToXMLFile'".
--   This file creates the table first and installs hooks only once.

RW_WeatherInstance = RW_WeatherInstance or {}

local rw = RW_WeatherInstance

local function rwWarning(message)
    if Logging ~= nil and Logging.warning ~= nil then
        Logging.warning("[RealisticWeather] %s", tostring(message))
    end
end

if rw.hooksInstalled ~= true then
    if WeatherInstance == nil then
        rwWarning("WeatherInstance is nil; RW_WeatherInstance hooks were not installed.")
    elseif Utils == nil then
        rwWarning("Utils is nil; RW_WeatherInstance hooks were not installed.")
    else
        -- Appended hook for WeatherInstance.saveToXMLFile.
        -- Saves RW fields only when they are meaningful.
        function rw.saveToXMLFile(self, xmlFile, key, ...)
            if self == nil or xmlFile == nil or key == nil then
                return
            end

            if self.isBlizzard == true then
                xmlFile:setBool(key .. "#isBlizzard", true)
            end

            if self.isDraught == true then
                xmlFile:setBool(key .. "#isDraught", true)
            end

            if self.snowForecast ~= nil then
                xmlFile:setFloat(key .. "#snowForecast", self.snowForecast)
            end
        end

        -- Overwrite hook for WeatherInstance.loadFromXMLFile.
        -- GIANTS Utils.overwrittenFunction passes the original function as superFunc.
        function rw.loadFromXMLFile(superFunc, self, xmlFile, key, ...)
            local result = nil

            if superFunc ~= nil then
                result = superFunc(self, xmlFile, key, ...)
            end

            if self == nil or xmlFile == nil or key == nil then
                return result
            end

            self.isBlizzard = xmlFile:getBool(key .. "#isBlizzard", false)
            self.isDraught = xmlFile:getBool(key .. "#isDraught", false)

            local snowForecast = xmlFile:getFloat(key .. "#snowForecast", -1.0)
            if snowForecast ~= nil and snowForecast >= 0 then
                self.snowForecast = snowForecast
            else
                self.snowForecast = nil
            end

            return result
        end

        -- Appended hook for WeatherInstance.readStream.
        function rw.readStream(self, streamId, ...)
            if self == nil or streamId == nil then
                return
            end

            self.isBlizzard = streamReadBool(streamId)
            self.isDraught = streamReadBool(streamId)

            local snowForecast = streamReadFloat32(streamId)
            if snowForecast ~= nil and snowForecast >= 0 then
                self.snowForecast = snowForecast
            else
                self.snowForecast = nil
            end
        end

        -- Appended hook for WeatherInstance.writeStream.
        function rw.writeStream(self, streamId, ...)
            if self == nil or streamId == nil then
                return
            end

            streamWriteBool(streamId, self.isBlizzard == true)
            streamWriteBool(streamId, self.isDraught == true)
            streamWriteFloat32(streamId, self.snowForecast or -1.0)
        end

        WeatherInstance.saveToXMLFile = Utils.appendedFunction(WeatherInstance.saveToXMLFile, rw.saveToXMLFile)
        WeatherInstance.loadFromXMLFile = Utils.overwrittenFunction(WeatherInstance.loadFromXMLFile, rw.loadFromXMLFile)
        WeatherInstance.readStream = Utils.appendedFunction(WeatherInstance.readStream, rw.readStream)
        WeatherInstance.writeStream = Utils.appendedFunction(WeatherInstance.writeStream, rw.writeStream)

        rw.hooksInstalled = true
    end
end
