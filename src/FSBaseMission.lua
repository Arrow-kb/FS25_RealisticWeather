RW_FSBaseMission = {}
local modDirectory = g_currentModDirectory

RW_FSBaseMission.FRUIT_TYPES_MOISTURE = {
    ["BARLEY"] = {
        ["LOW"] = 0.12,
        ["HIGH"] = 0.135
    },
    ["WHEAT"] = {
        ["LOW"] = 0.12,
        ["HIGH"] = 0.145
    },
    ["OAT"] = {
        ["LOW"] = 0.12,
        ["HIGH"] = 0.18
    },
    ["CANOLA"] = {
        ["LOW"] = 0.08,
        ["HIGH"] = 0.1
    },
    ["SOYBEAN"] = {
        ["LOW"] = 0.125,
        ["HIGH"] = 0.135
    },
    ["SORGHUM"] = {
        ["LOW"] = 0.17,
        ["HIGH"] = 0.2
    },
    ["RICELONGGRAIN"] = {
        ["LOW"] = 0.19,
        ["HIGH"] = 0.22
    },
    ["MAIZE"] = {
        ["LOW"] = 0.15,
        ["HIGH"] = 0.2
    },
    ["SUNFLOWER"] = {
        ["LOW"] = 0.09,
        ["HIGH"] = 0.1
    },
    ["GRASS"] = {
        ["LOW"] = 0.18,
        ["HIGH"] = 0.22
    },
    ["OILSEEDRADISH"] = {
        ["LOW"] = 0.2,
        ["HIGH"] = 0.22
    },
    ["PEA"] = {
        ["LOW"] = 0.14,
        ["HIGH"] = 0.15
    },
    ["SPINACH"] = {
        ["LOW"] = 0.2,
        ["HIGH"] = 0.22
    },
    ["SUGARCANE"] = {
        ["LOW"] = 0.22,
        ["HIGH"] = 0.26
    },
    ["SUGARBEET"] = {
        ["LOW"] = 0.22,
        ["HIGH"] = 0.26
    },
    ["COTTON"] = {
        ["LOW"] = 0.1,
        ["HIGH"] = 0.12
    },
    ["GREENBEAN"] = {
        ["LOW"] = 0.175,
        ["HIGH"] = 0.185
    },
    ["CARROT"] = {
        ["LOW"] = 0.135,
        ["HIGH"] = 0.155
    },
    ["PARSNIP"] = {
        ["LOW"] = 0.135,
        ["HIGH"] = 0.155
    },
    ["BEETROOT"] = {
        ["LOW"] = 0.15,
        ["HIGH"] = 0.17
    },
    ["RICE"] = {
        ["LOW"] = 0.22,
        ["HIGH"] = 0.24
    },
    ["POTATO"] = {
        ["LOW"] = 0.18,
        ["HIGH"] = 0.2
    }
}

function RW_FSBaseMission:getHarvestScaleMultiplier(superFunc, fruitTypeIndex, sprayLevel, plowLevel, limeLevel, weedsLevel, stubbleLevel, rollerLevel, beeYieldBonusPercentage, moisture)

    local baseYield = superFunc(self, fruitTypeIndex, sprayLevel, plowLevel, limeLevel, weedsLevel, stubbleLevel, rollerLevel, beeYieldBonusPercentage)

    if moisture == nil then return baseYield end


    local moistureFactor = 1
    local fruitType = g_fruitTypeManager:getFruitTypeNameByIndex(fruitTypeIndex)
    local fruitTypeMoistureFactor = RW_FSBaseMission.FRUIT_TYPES_MOISTURE[fruitType]

    if fruitTypeMoistureFactor ~= nil then

        local lowMoisture = fruitTypeMoistureFactor.LOW
        local highMoisture = fruitTypeMoistureFactor.HIGH
        local perfectMoisture = (highMoisture + lowMoisture) / 2

        if moisture >= perfectMoisture - 0.0025 and moisture <= perfectMoisture + 0.0025 then
            moistureFactor = 1.5
        elseif moisture < lowMoisture then
            moistureFactor = moisture / lowMoisture
        elseif moisture < perfectMoisture then
            moistureFactor = 1 + (moisture / perfectMoisture) * 0.2
        elseif moisture > highMoisture then
            moistureFactor = highMoisture / moisture
        elseif moisture > perfectMoisture then
            moistureFactor = 1 + (perfectMoisture / moisture) * 0.2
        end

    end

    return baseYield * math.clamp(moistureFactor, 0.5, 1.5)

end

FSBaseMission.getHarvestScaleMultiplier = Utils.overwrittenFunction(FSBaseMission.getHarvestScaleMultiplier, RW_FSBaseMission.getHarvestScaleMultiplier)


local function fixInGameMenu(frame, pageName, uvs, position, predicateFunc)

	local inGameMenu = g_gui.screenControllers[InGameMenu]
	position = position or #inGameMenu.pagingElement.pages + 1

	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu.pageAnimals then
			position = i
            break
		end
	end
	
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

	inGameMenu:exposeControlsAsFields(pageName)

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.elements, i)
			table.insert(inGameMenu.pagingElement.elements, position, child)
			break
		end
	end

	for i = 1, #inGameMenu.pagingElement.pages do
		local child = inGameMenu.pagingElement.pages[i]
		if child.element == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.pages, i)
			table.insert(inGameMenu.pagingElement.pages, position, child)
			break
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	inGameMenu:addPageTab(inGameMenu[pageName], modDirectory .. "gui/icons.dds", GuiUtils.getUVs(uvs))

	for i = 1, #inGameMenu.pageFrames do
		local child = inGameMenu.pageFrames[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pageFrames, i)
			table.insert(inGameMenu.pageFrames, position, child)
			break
		end
	end

	inGameMenu:rebuildTabList()

end


function RW_FSBaseMission:onStartMission()

	RWSettings.applyDefaultSettings()

    g_overlayManager:addTextureConfigFile(modDirectory .. "gui/icons.xml", "realistic_weather")

    if g_modIsLoaded["FS25_RealisticLivestock"] then RW_Weather.isRealisticLivestockLoaded = true end
    if g_modIsLoaded["FS25_ExtendedGameInfoDisplay"] then RW_GameInfoDisplay.isExtendedGameInfoDisplayLoaded = true end

    --local realisticWeatherFrame = RealisticWeatherFrame.new() 
	--g_gui:loadGui(modDirectory .. "gui/RealisticWeatherFrame.xml", "RealisticWeatherFrame", realisticWeatherFrame, true)

    --fixInGameMenu(realisticWeatherFrame, "realisticWeatherFrame", {260,0,256,256}, 4, function() return true end)

    --realisticWeatherFrame:initialize()

    MoistureArgumentsDialog.register()

    

    for i = 1, 5 do

        --local path = modDirectory .. "i3d/waterPlane" .. i .. ".i3d"
        --local waterPlane = g_i3DManager:loadI3DFile(path, true, true)

        --link(getRootNode(), waterPlane)

        --local x, z = -770.4586181640625, 232.4373016357422

        --local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)

        --local lower = math.random() > 0.5
    
        --if lower then
        --    setWorldTranslation(waterPlane, x - math.random(1, 30), terrainHeight + 0.05, z - math.random(1, 30))
        --else
        --    setWorldTranslation(waterPlane, x + math.random(1, 30), terrainHeight + 0.05, z + math.random(1, 30))
        --end
        --setScale(waterPlane, math.random(3, 10), 1, math.random(3, 10))

    end



end

FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, RW_FSBaseMission.onStartMission)


function RW_FSBaseMission:sendInitialClientState(connection, _, _)

    connection:sendEvent(RW_BroadcastSettingsEvent.new())

end

FSBaseMission.sendInitialClientState = Utils.prependedFunction(FSBaseMission.sendInitialClientState, RW_FSBaseMission.sendInitialClientState)