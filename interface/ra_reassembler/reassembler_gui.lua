require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"

ra = {}

function init()
	ra.renameVisible = false
	self.currentUpgrades = {}
	self.highlightImages = config.getParameter("highlightImages")
	self.autoRefreshRate = config.getParameter("autoRefreshRate")
	self.autoRefreshTimer = self.autoRefreshRate --timer for calling updateGui
	ra.ElementIsSet = false --Marker for resetting weapon element ONCE when the modgun is available
	ra.LastWeaponSeed = 0
	ra.PreviewScale = 2 -- Default scale of the preview image
	self.gunImageZero = {40,85}

	self.highlightPulseTimer = 0
	updateGui()
	
	ra.acceptableGun = {"commonpistol","uncommonpistol","rarepistol","commonmachinepistol","uncommonmachinepistol","raremachinepistol","commonassaultrifle","uncommonassaultrifle","rareassaultrifle","commonsniperrifle","uncommonsniperrifle","raresniperrifle","commonshotgun","uncommonshotgun","rareshotgun","commongrenadelauncher","uncommongrenadelauncher","raregrenadelauncher","commonrocketlauncher","uncommonrocketlauncher","rarerocketlauncher"}

	ra.acceptableGunType = {"pistol","machinepistol","assaultrifle","sniperrifle","shotgun","grenadelauncher","rocketlauncher"}
	
	ra.elementalTypes = { --for lookup and appropriate RadioGroup settings
		[-1] = "physical",
		[0] = "fire",
		[1] = "electric",
		[2] = "ice",
		[3] = "poison"
	}
	
	self.rangedPaletteIndexes = { --dyes dyeColorIndex+1
		"", --1 dye remover
		"", --2 black
		"4", --3 grey
		"", --4 white
		"1", --5 red
		"3", --6 orange
		"", --7 yellow
		"2", --8 green (actually teal, fix it later)
		"", --9 blue
		"5", --10 purple
		"", --11 pink
		"" --12 brown
	}
	self.meleePaletteIndexes = { --dyes dyeColorIndex+1
		"", --1 dye remover
		"", --2 black
		"4", --3 grey
		"", --4 white
		"1", --5 red
		"3", --6 orange
		"", --7 yellow
		"2", --8 green (actually teal, fix it later)
		"", --9 blue
		"5", --10 purple
		"", --11 pink
		"" --12 brown
	}
	ra.rarityTiers = {"common","uncommon","rare","legendary"}
	ra.craftedTiers = {"iron", "tungsten", "titanium", "durasteel", "aegisalt", "violium", "ferozium"}
	ra.altModeElemental =  {"lance", "explosiveburst"} --those abilities are elemental-only
end

function ra.getPaletteSwap(index) -- build palette swap directives. index = dye index
	if index < 0 or index > 11 then --if index out of bounds [0, 11]
		return false
	end
	local paletteSwaps = ""
	if not ra.isModGun() then --there is not mod gun
		return nil
	end
	local builderConfig = {} --if there is a builderConfig in weapon 1, pick it up
	if root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0)).config.builderConfig[1] then
		builderConfig = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0)).config.builderConfig[1]
	end
	local swap = ""
	local palindex = tonumber(self.rangedPaletteIndexes[index+1]) --change HERE for melee
	if not palindex then --TEMPORARY - if index is not a number. Change to direct palette reformat later
		return nil
	end
	if builderConfig.palette then --try to get a palette path from builderConfig
		local palette = root.assetJson(builderConfig.palette) --let's hope there are absolute paths everywhere
		local selectedSwaps = palette.swaps[palindex] --indexing starts from 1, hence +1
		for vanillacolor, modcolor in pairs(selectedSwaps) do --reformat selected swap to single string
			swap = string.format("%s?replace=%s=%s", swap, vanillacolor, modcolor)
		end
		return swap
	else
		return nil
	end
 end

function ra.getAbsImage(path) --removes modifying instructions from the path
	if not path or type(path) ~= "string" then
		return false
	end
	local i,j = string.find(path, "?") --get first index of instructions
	if i then
		return string.sub(path,1,i-1) --return the path without instructions
	else
		return false
	end
end

function SetElementOnce(modgun) --call only when there is a suitable modgun!!
	if ra.ElementIsSet and (ra.LastWeaponSeed == modgun.parameters.seed) then -- If the Element is already set, do nothing
		return false
	else -- Else: set weapon element and save the marker + seed
		ra.ElementIsSet = true
		ra.LastWeaponSeed = modgun.parameters.seed
		for index,elemType in pairs(ra.elementalTypes) do
			if modgun.parameters.elementalType == nil then
				widget.setSelectedOption("ra_radioElemental",-1)
				widget.setText("ra_PriceScrArea.ra_lblDebugText","Radio selected: "..tostring(widget.getSelectedOption("ra_radioElemental")).."\n".."Weapon type: physical".."\n")
				break
			end
			if modgun.parameters.elementalType == elemType then --if weapon's elem is found
				widget.setSelectedOption("ra_radioElemental",index)
				-- index: -1: physical, 0: fire, 1: electric, 2: ice, 3: poison
				widget.setText("ra_PriceScrArea.ra_lblDebugText","Radio selected: "..tostring(widget.getSelectedOption("ra_radioElemental")).."\n".."Weapon type: "..modgun.parameters.elementalType.."\n".."Weapon type index: "..tostring(index))
				break
			end
		end
		return true
	end
end

function updateGui()
	--GUN PREVIEW--
	---[[
	if ra.isModGun() and ra.goodGun(0) then --if there is a modifyable gun
		local modgun = world.containerItemAt(pane.containerEntityId(), 0)
		local modguncfg = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0))

		local templategun 
		local templateguncfg
		if ra.isTemplateGun() and ra.goodGun(1) and ra.sametypeGuns() then --if there is a matching template gun
			templategun = world.containerItemAt(pane.containerEntityId(), 1)
			templateguncfg = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 1))
		end
		
		
		SetElementOnce(modgun) -- Set weapon element radiogroup to current elem; called once for every new modgun
		-- local scale = 2
		local gunimage = modgun.parameters.inventoryIcon --try copy gun's icon images
		if not gunimage then --if there are none grab them from config
			gunimage = modguncfg.config.inventoryIcon
		end
		if templategun then --if we have a good template gun as well
			for i,part in ipairs(gunimage) do --iterate weapon parts, max i = 3
				local checkname = "ra_chkPart"..tostring(i)
				if widget.getChecked(checkname) then --if we need to copy that part
					if templategun.parameters.inventoryIcon then --if there are custom parts in template
						gunimage[i] = templategun.parameters.inventoryIcon[i] --try copying part i
					else --if template uses only vanilla parts
						gunimage[i] = templateguncfg.config.inventoryIcon[i] --copy from config (vanilla part)
					end
					if not gunimage[i] then --if no custom part in template with this index => we copied nil
						gunimage[i] = templateguncfg.config.inventoryIcon[i] --copy from config (vanilla part)
					end
				end
			end
			--[[
			if not gunimage then --if there are no images in the tempalte gun itself
				gunimage = templateguncfg.config.inventoryIcon
			end
			--]]
			--[[ TODO LATER
			if modguncfg.config.paletteSwaps then --if native palette exists - recolor accordingly
				for i,part in ipairs(gunimage) do
					part.image = ra.getAbsImage(part.image) .. modguncfg.config.paletteSwaps
				end
			end 
			]]--
		end
		
		--Applying dyes--
		--[[ TODO LATER
		for i,part in ipairs(gunimage) do
			if world.containerItemAt(pane.containerEntityId(), 2+i) and root.itemConfig(world.containerItemAt(pane.containerEntityId(), 2+i)).config.category == "clothingDye" then --if there is a dye
				local dyeIndex = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 2+i)).config.dyeColorIndex
				if dyeIndex and ra.getPaletteSwap(dyeIndex) then --if we got a valid index and it returns a good palette
					local paletteSwap = ra.getPaletteSwap(dyeIndex)
					if paletteSwap == "" then --empty palette => reset color
						part.image = ra.getAbsImage(part.image) .. modguncfg.config.paletteSwaps
					else --we have a good palette => use it
						part.image = ra.getAbsImage(part.image) .. paletteSwap
					end
				end
			end
		end
		]]--	
		
		--Drawing preview
		for i,part in ipairs(gunimage) do --iterate over gunimage array
			local imgWidget = "ra_gunImage"..tostring(i) --get widget name
			widget.setImage(imgWidget,part.image)
			widget.setImageScale(imgWidget,ra.PreviewScale)
			part.position = { root.imageSize(part.image)[1], 0} --calculate size from image part (only X)
			local imgpos = {0,0}
			for j=2,i do
				imgpos = vec2.add(imgpos,gunimage[j-1].position) --sum all previous image parts' sizes
			end
			widget.setPosition(imgWidget, vec2.add(self.gunImageZero, vec2.mul(imgpos,ra.PreviewScale))) --shift images
		end
		
	else --No modgun available or not suitable item
		widget.setImage("ra_gunImage1","")
		widget.setImage("ra_gunImage2","")
		widget.setImage("ra_gunImage3","")
		if ra.ElementIsSet then -- Reset element marker
			ra.ElementIsSet = false
			widget.setSelectedOption("ra_radioElemental",-1)
			widget.setText("ra_PriceScrArea.ra_lblDebugText","Yup!")
		end
	end
	--]]
end

function ra.setHighlight(widgetName)
	self.highlightImage = self.highlightImages[widgetName] or ""
end

function update(dt)
	--this command here checks with <dt> interval if the RpcPromises are completed and runs corresponding functions if they are
	promises:update()
	
	self.autoRefreshTimer = math.max(0, self.autoRefreshTimer - dt) --gradually reduce timer every tick
	if self.autoRefreshTimer == 0 then
		updateGui()
		self.autoRefreshTimer = self.autoRefreshRate --reset timer after updateGui is called
	end
	widget.setText("ra_lblDebug", tostring(self.autoRefreshTimer))

	if self.highlightImage then
		self.highlightPulseTimer = self.highlightPulseTimer + dt
		local highlightDirectives = string.format("?multiply=FFFFFF%2x", math.floor((math.cos(self.highlightPulseTimer * 8) * 0.5 + 0.5) * 255))
		--widget.setImage("imgHighlight", self.highlightImage .. highlightDirectives)
	end
end

function ra.isModGun()
	if world.containerItemAt(pane.containerEntityId(), 0) then
		return true
	else
		return false
	end
end

function ra.isAssembledGun()
	if world.containerItemAt(pane.containerEntityId(), 2) then
		return true
	else
		return false
	end
end

function ra.isTemplateGun()
	if world.containerItemAt(pane.containerEntityId(), 1) then
		return true
	else
		return false
	end
end

function ra.goodGun(itemindex)
	local guntype =  ra.getWeaponType(world.containerItemAt(pane.containerEntityId(), itemindex).name) --get weapon type without "common", "rare" etc
	if not guntype or not ra.acceptableGunType then --if we have null weapon or init isn't complete yet
		return false
	end
	for _,goodtype in ipairs(ra.acceptableGunType) do
		if guntype == goodtype then --if weapon name matches any good one - we can work with it
			return true
		end
	end
	return false
end

function ra.getWeaponType(name)
	if not name or type(name) ~= "string" then --if we have some strange name
		return false
	end
	local i1, i2 = string.find(name, "common")
	if string.find(name, "common") ~= nil and i1 == 1 then
		local cropname = string.gsub(name, "common", "", 1)
		return cropname
	end
	i1, i2 = string.find(name, "uncommon")
	if string.find(name, "uncommon") ~= nil and i1 == 1 then
		local cropname = string.gsub(name, "uncommon", "", 1)
		return cropname
	end
	i1, i2 = string.find(name, "rare")
	if string.find(name, "rare") ~= nil and i1 == 1 then
		local cropname = string.gsub(name, "rare", "", 1)
		return cropname
	end
	return false
end

function ra.sametypeGuns()
	local modtype =  ra.getWeaponType(world.containerItemAt(pane.containerEntityId(), 0).name) --get weapon name
	local templatetype =  ra.getWeaponType(world.containerItemAt(pane.containerEntityId(), 1).name) --get template weapon name
	if modtype == templatetype then
		return true
	end
	return false
end

function ra.testCallback(widgetName)
	widget.playSound("/sfx/interface/ship_confirm1.ogg")
end

function ra.renameButton(widgetName)
	if not ra.isModGun() or ra.isAssembledGun() then --if there is no gun or pick-up slot is occupied
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	ra.renameVisible = not ra.renameVisible
	widget.setVisible("ra_boxRename", ra.renameVisible)
	widget.focus( ra.renameVisible and "ra_boxRename" or "ra_btnRename" )
end

function ra.reconstructButton(widgetName)
	if not ra.isModGun() or not ra.isTemplateGun() or ra.isAssembledGun() then --if there is no gun or no template gun or pick-up slot is occupied
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	if not ra.goodGun(0) or not ra.sametypeGuns() then --if the gun is not "good" or the guns are different
		widget.playSound("/sfx/interface/clickon_error_single.ogg")
		return false
	end
	
	local copySound = widget.getChecked("ra_chkSound")
	local copyAltMode = widget.getChecked("ra_chkAltMode")
	if copyAltMode then --AltMode checks
		modgun = world.containerItemAt(pane.containerEntityId(), 0)
		template = world.containerItemAt(pane.containerEntityId(), 1)
		for i = 1, #ra.altModeElemental do --check Elemental blacklist
			if(ra.altModeElemental[i] == template.parameters.altAbilityType) and modgun.parameters.elementalType == "physical" then --if we copy elem-only mode over physical dmg
				widget.playSound("/sfx/interface/clickon_error_single.ogg")
				return false
			end
		end
	end
	local copyParts = {}
	for i=1, 3 do
		local chkName = "ra_chkPart"..tostring(i)
		copyParts[i] = widget.getChecked(chkName)
	end
	world.sendEntityMessage(pane.containerEntityId(), "reconstructGun", copyParts, copySound, copyAltMode, nil)
	widget.playSound("/sfx/objects/penguin_welding4.ogg")
end

function ra.resetButton(widgetName)
	if not ra.isModGun() or ra.isAssembledGun() or not ra.goodGun(0) then --if there is no gun or pick-up slot is occupied, or the gun is not "good"
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	local dialogConfig = root.assetJson("/interface/confirmation/reassemblerconfirm.config:gun_reset")
	promises:add(player.confirm(dialogConfig), function (choice)
		if choice then
			--sb.logWarn("[HELP] CONFIRMATION: YES")
			world.sendEntityMessage(pane.containerEntityId(), "resetGun")
			widget.playSound("/sfx/objects/cropshipper_box_lock3.ogg")
		else
			--sb.logWarn("[HELP] CONFIRMATION: NO")
		end
	end)
	widget.playSound("/sfx/interface/ship_confirm1.ogg")
end

function ra.scanButton(widgetName)
	if not ra.isModGun() or not ra.goodGun(0) then --if there is no gun or the item is not a good gun
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	world.sendEntityMessage(pane.containerEntityId(), "scanGun")
	local modguncfg = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0))
	--[[
	for key,value in pairs(modguncfg.config.animationParts) do
		sb.logInfo("[HELP DUMP cfg.config]"..key.." : "..tostring(value))
	end
	sb.logInfo("[HELP IC ]"..modguncfg.config.animationParts.butt)--]]
	--sb.logWarn("[HELP IC ]"..key.." : "..type(modguncfg.parameters.animationParts.butt))
	widget.setImage("ra_gunImage",modguncfg.config.animationParts.butt) 
	widget.playSound("/sfx/interface/scan.ogg")
end

function ra.debugButton(widgetName)
	--world.sendEntityMessage(pane.containerEntityId(), "debugInfo")
	widget.setVisible("ra_lblDebug", true)
	--[[
	for key,value in pairs(root.itemConfig(world.containerItemAt(pane.containerEntityId(), 3)).config) do
		sb.logInfo("[HELP DUMP dye.config]"..key.." : "..tostring(value))
	end
	--]]
	for key,value in pairs((world.containerItemAt(pane.containerEntityId(), 0)).parameters) do
		sb.logInfo("[HELP DUMP gun params]"..key.." : "..tostring(value))
	end
	
	--[[
	for key,value in pairs(root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0))) do
		sb.logInfo("[HELP DUMP gun config]"..key.." : "..tostring(value))
	end
	]]--
	--sb.logWarn("[PALETTE INDEX  ]"..dyeIndex)
	
	--local dyeIndex = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 3)).config.dyeColorIndex
	--sb.logWarn("[PALETTE  ]"..tostring(ra.getPaletteSwap(4)))
	widget.playSound("/sfx/interface/scan.ogg")
end

function ra.renameThis(widgetName)
  ra.renameVisible = false
  widget.setVisible("ra_boxRename", false)
  widget.focus("ra_btnRename")
  local newName = widget.getText("ra_boxRename")
  if newName then
	world.sendEntityMessage(pane.containerEntityId(), "renameGun", newName)
  end
end