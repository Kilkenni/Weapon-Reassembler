require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"

ra = {}
ra.dye1Option = {}
ra.dye2Option = {}
ra.dye3Option = {}

function init()
	ra.renameVisible = false
	self.currentUpgrades = {}
	self.highlightImages = config.getParameter("highlightImages")
	self.autoRefreshRate = config.getParameter("autoRefreshRate")
	self.autoRefreshTimer = self.autoRefreshRate --timer for calling updateGui
	ra.ElementIsSet = false --Marker for resetting weapon element ONCE when the modgun is available
	ra.LastWeaponSeed = 0
	ra.PreviewScale = 2 -- Default scale of the preview image
	
	ra.palettepath = "/objects/wiring/ra_reassembler/ra_palette.weaponcolors" --palette swap file path
	ra.palettes = root.assetJson(util.absolutePath(directory, ra.palettepath)) --init table with palettes
	--convert keys in ra.palettes.dyeIndexes into integers
	temptable = {}
	for key, value in pairs(ra.palettes.dyeIndexes) do
		temptable[tonumber(key)] = value
	end
	ra.palettes.dyeIndexes = temptable
	
	ra.dyeSettings = {
		[1] = { dyeName = "", variant = 1, maxvariant = 1 },
		[2] = { dyeName = "", variant = 1, maxvariant = 1 },
		[3] = { dyeName = "", variant = 1, maxvariant = 1 }
	}
	--[[
	ra.dyeIndexes = { --vanilla dyes reference index, now kept directly in palettes' file
		[0] = "dyeremover",
		[1] = "black",
		[2] = "grey",
		[3] = "white",
		[4] = "red",
		[5] = "orange",
		[6] = "yellow",
		[7] = "green",
		[8] = "blue",
		[9] = "purple",
		[10] = "pink",
		[11] = "brown"
	}
	]]--
	
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
		"", --0+1=1 dye remover
		"", --1+1=2 black
		"4", --2+1=3 grey
		"", --3+1=4 white
		"1", --4+1=5 red
		"3", --5+1=6 orange
		"", --6+1=7 yellow
		"2", --7+1=8 green (actually teal, fix it later)
		"", --8+1=9 blue
		"5", --9+1=10 purple
		"", --10+1=11 pink
		"" --11+1=12 brown
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

function ra.getDyeName(itemslot)
	if world.containerItemAt(pane.containerEntityId(), itemslot+2) then --if there is something in the slot at all
		if root.itemConfig(world.containerItemAt(pane.containerEntityId(), itemslot+2)).config.category == "clothingDye" then --if there is a dye in this slot
			local dyeName = ra.palettes.dyeIndexes[root.itemConfig(world.containerItemAt(pane.containerEntityId(), itemslot+2)).config.dyeColorIndex]
			if dyeName == nil then --If this dye's name can't be found (dye has no index or no such index in our base)
				return nil
			end
			return dyeName --if all is good, return the name
		end
		return false --if the item in the slot is not a dye
	end
	return false --by default
end

function ra.getPaletteSwap(weaponType,dyeName,variant)
	if not weaponType or not dyeName then --weaponType is not recognized (or no dyeName, just in case)
		return nil
	end
	local paletteSwap = ra.palettes[weaponType][dyeName][variant] --try to get swap for that weapon type and dye 
	if not paletteSwap then
		return false --no such dyeName found (most probably not implemented yet)
	end
	local swap = ""
	for origcolor, modcolor in pairs(paletteSwap) do --reformat selected swap to single string
		swap = string.format("%s?replace=%s=%s", swap, origcolor, modcolor)
	end
	return swap
end

function ra.HasTrue(boolarray) --returns true if at least 1 array member is true. Returns false otherwise.
	for i,value in ipairs(boolarray) do
		if value == true then
			return true
		end
	end
	return false
end

function ra.HasDye() --returns true if there is at least 1 usable dye in dye slot. Returns false otherwise
	for i=1,3 do
		if world.containerItemAt(pane.containerEntityId(), 2+i) then --if there is an item in the slot
			if ra.getDyeName(i) then --if we can determine dye name for this item (it is not false or nil)
				return true
			end
		end
	end
	return false
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

function ra.getAbsPalette(path) --removes image path from the path, only palette remains
	if not path or type(path) ~= "string" then
		return false
	end
	local i,j = string.find(path, "?") --get first index of instructions
	if i then
		return string.sub(path,i,string.len(path)) --return the path without iamge path, only instructions
	else
		return false
	end
end

function GetElementalIndex(modgun) --searches elementalTypes table for the element and returns its index
	if modgun.parameters == nil then --if empty modgun, just to be sure
		return nil
	end
	for index,elemType in pairs(ra.elementalTypes) do
		if modgun.parameters.elementalType == nil then --if the element is "physical" there is no such field at all; that requires special handling
			return -1
		end
		if modgun.parameters.elementalType == elemType then --if weapon's elem is found
			return index
		end
	end
end

function SetElementOnce(modgun) --call only when there is a suitable modgun!!
	if ra.ElementIsSet and (ra.LastWeaponSeed == modgun.parameters.seed) then -- If the Element is already set, do nothing
		return false
	else -- Else: set weapon element and save the marker + seed
		ra.ElementIsSet = true
		ra.LastWeaponSeed = modgun.parameters.seed
		local index = GetElementalIndex(modgun) --calculate elem index in the table
		widget.setSelectedOption("ra_radioElemental",index) --set this index as a selected option
		widget.setText("ra_PriceScrArea.ra_lblErrorText","Weapon damage: "..ra.elementalTypes[index].."\n".."Weapon damage index: "..tostring(index))
		
		return true
	end
end

function ra.dye1Option.up() --top dye
	if ra.dyeSettings[1].variant < ra.dyeSettings[1].maxvariant then
		ra.dyeSettings[1].variant = ra.dyeSettings[1].variant + 1 --if current variant < maxvariant, increase
		widget.setText("ra_lblDye1",tostring(ra.dyeSettings[1].variant) .. "/" .. tostring(ra.dyeSettings[1].maxvariant)) --update visual index
		updateGui() --call instant redraw
	end
end

function ra.dye1Option.down()
	if ra.dyeSettings[1].variant > 1 then
		ra.dyeSettings[1].variant = ra.dyeSettings[1].variant - 1 --if current variant > 1, decrease
		widget.setText("ra_lblDye1",tostring(ra.dyeSettings[1].variant) .. "/" .. tostring(ra.dyeSettings[1].maxvariant)) --update visual index
		updateGui() --call instant redraw
	end
end

function ra.dye2Option.up() --mid dye
	if ra.dyeSettings[2].variant < ra.dyeSettings[2].maxvariant then
		ra.dyeSettings[2].variant = ra.dyeSettings[2].variant + 1 --if current variant < maxvariant, increase
		widget.setText("ra_lblDye2",tostring(ra.dyeSettings[2].variant) .. "/" .. tostring(ra.dyeSettings[2].maxvariant)) --update visual index
		updateGui() --call instant redraw
	end
end

function ra.dye2Option.down()
	if ra.dyeSettings[2].variant > 1 then
		ra.dyeSettings[2].variant = ra.dyeSettings[2].variant - 1 --if current variant > 1, decrease
		widget.setText("ra_lblDye2",tostring(ra.dyeSettings[2].variant) .. "/" .. tostring(ra.dyeSettings[2].maxvariant)) --update visual index
		updateGui() --call instant redraw
	end
end

function ra.dye3Option.up() --bottom dye
	if ra.dyeSettings[3].variant < ra.dyeSettings[3].maxvariant then
		ra.dyeSettings[3].variant = ra.dyeSettings[3].variant + 1 --if current variant < maxvariant, increase
		widget.setText("ra_lblDye3",tostring(ra.dyeSettings[3].variant) .. "/" .. tostring(ra.dyeSettings[3].maxvariant)) --update visual index
		updateGui() --call instant redraw
	end
end

function ra.dye3Option.down()
	if ra.dyeSettings[3].variant > 1 then
		ra.dyeSettings[3].variant = ra.dyeSettings[3].variant - 1 --if current variant > 1, decrease
		widget.setText("ra_lblDye3",tostring(ra.dyeSettings[3].variant) .. "/" .. tostring(ra.dyeSettings[3].maxvariant)) --update visual index
		updateGui() --call instant redraw
	end
end

function ra.sameDye(slot) --slot = 1..3
	if not ra.getDyeName(slot) then --wrong item in dye slot
		return nil
	end
	if ra.getDyeName(slot) == ra.dyeSettings[slot].dyeName then 
		return true --current dye in slot didn't change
	else
		return false --current dye did change
	end
	return false --let's make an update by default, just in case
end

function ra.updateDye(slot) --Resets dye settings for the slot. Slot = 1..3	
	local weaponType = ""
	if ra.goodGun(0) then --if there is a gun in "modgun" slot
		weaponType = "ranged"
	end
	if weaponType == "" then --if weapon type is still undefined, emergency return
		return nil
	end
	if not ra.getDyeName(slot) then --if there's something wrong with the new dye
		widget.setVisible("ra_lblDye"..tostring(slot),false) --hide number of variants
		widget.setVisible("dye"..tostring(slot).."Variant",false) --hide spinner
		ra.dyeSettings[slot].dyeName = "" --reset dye name
		return false
	end
	ra.dyeSettings[slot].dyeName = ra.getDyeName(slot) --save new dye
	ra.dyeSettings[slot].maxvariant = #(ra.palettes[weaponType][ra.dyeSettings[slot].dyeName])
	ra.dyeSettings[slot].variant = 1 --by default
	if ra.dyeSettings[slot].maxvariant == 0 then --if there are no variants at all, set default to 0
		ra.dyeSettings[slot].variant = 0
	end
	widget.setText("ra_lblDye"..tostring(slot),tostring(ra.dyeSettings[slot].variant) .. "/" .. tostring(ra.dyeSettings[slot].maxvariant))
	widget.setVisible("ra_lblDye"..tostring(slot),true) --show number of variants
	widget.setVisible("dye"..tostring(slot).."Variant",true) --show spinner
	return true
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
		-- local scale = 2 --removed, scale is now a global variable for possible preview zooming
		local gunimage = modgun.parameters.inventoryIcon --try copy gun's icon images
		if not gunimage then --if there are none grab them from config
			gunimage = modguncfg.config.inventoryIcon
		end
		if templategun then --if we have a good template gun as well
			for i,part in ipairs(gunimage) do --iterate weapon parts, max i = 3
				local checkname = "ra_chkPart"..tostring(i)
				local prePaletteSwap = ""
				if modguncfg.config.paletteSwaps then
					prePaletteSwap = modguncfg.config.paletteSwaps --preliminary palette swap
				end
				if widget.getChecked(checkname) then --if we need to copy that part			
					if templategun.parameters.inventoryIcon then --if there are custom parts in template
						gunimage[i] = templategun.parameters.inventoryIcon[i] --try copying part i
					else --if template uses only vanilla parts
						gunimage[i] = templateguncfg.config.inventoryIcon[i] --copy from config (vanilla part)
					end
					if not gunimage[i] then --if no custom part in template with this index => we copied nil
						gunimage[i] = templateguncfg.config.inventoryIcon[i] --copy from config (vanilla part)
					end
					if modgun.parameters.inventoryIcon then --if orig gun has custom graphics
						if ra.getAbsPalette(modgun.parameters.inventoryIcon[i]) then --if we can get palette from it
							gunimage[i].image = ra.getAbsImage(gunimage[i].image) .. ra.getAbsPalette(modgun.parameters.inventoryIcon[i]) --take recolor from original custom graphics
						else --use palette from config if it exists (or append empty string otherwise)
							gunimage[i].image = ra.getAbsImage(gunimage[i].image) .. prePaletteSwap 
						end
					else
						gunimage[i].image = ra.getAbsImage(gunimage[i].image) .. prePaletteSwap
					end
				end
			end
			--[[
			if not gunimage then --if there are no images in the template gun itself
				gunimage = templateguncfg.config.inventoryIcon
			end
			--]]
			--[[
			if modguncfg.config.paletteSwaps then --if native palette exists - recolor accordingly
				for i,part in ipairs(gunimage) do
					part.image = ra.getAbsImage(part.image) .. modguncfg.config.paletteSwaps
				end
			end 
			]]--
		end
		
		for i=1,3 do
			if not ra.sameDye(i) then --dye in slot i changed OR not-a-dye
				ra.updateDye(i) --if it is not a dye it just hides the number of variants
			end
		end
		
		--Applying dyes to preview--
		for i,part in ipairs(gunimage) do --iterate over gun image parts
			if world.containerItemAt(pane.containerEntityId(), 2+i) then --if there is something in the slot
				local dyeName = ra.getDyeName(i) --slots 0..2 are for weapons, but +2 is already in the func
				if dyeName == false then --not a dye
					widget.setText("ra_PriceScrArea.ra_lblErrorText",">Unknown item in dye slot "..tostring(i))
				end
				if dyeName == nil then --dye without or with unknown index
					widget.setText("ra_PriceScrArea.ra_lblErrorText",">Non-standart dye in slot "..tostring(i))
				end
				if dyeName then --this is a vanilla dye or a dye with an index we know
					local paletteSwap = ""
					--widget.setVisible("ra_lblDye"..tostring(i),true) --show number of variants
					--RESET dye variant in dye changed!
					--local paletteVariant = 
					if ra.goodGun(0) then --it checks if it is actually a gun, too!
						paletteSwap = ra.getPaletteSwap("ranged",dyeName,ra.dyeSettings[i].variant) --use ranged palettes, dyeName, selected variant
					end
					if paletteSwap and paletteSwap ~= "" then --got our palette, it's not false and not empty (if it is, retain orig colors)
						part.image = ra.getAbsImage(part.image) .. paletteSwap --recolor
					end
				else
					--widget.setVisible("ra_lblDye"..tostring(i),false) --hide number of variants
				end
			end
			
		end
			
		
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
	for _,goodguntype in ipairs(ra.acceptableGunType) do
		if guntype == goodguntype then --if weapon name matches any good one - we can work with it
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
	--Reading modification settings
	local copySound = widget.getChecked("ra_chkSound")
	local copyAltMode = widget.getChecked("ra_chkAltMode")
	local copyParts = {}
	for i=1, 3 do
		local chkName = "ra_chkPart"..tostring(i)
		copyParts[i] = widget.getChecked(chkName)
	end
	
	--GUN PRE_CHECKS--
	if not ra.isModGun() then --if there is no gun to work on
		widget.playSound("/sfx/interface/clickon_error.ogg")
		widget.setText("ra_PriceScrArea.ra_lblErrorText",">No gun to modify")
		return false
	end
	if not ra.goodGun(0) then --if the gun is not "good". That's obvious
		widget.playSound("/sfx/interface/clickon_error_single.ogg")
		widget.setText("ra_PriceScrArea.ra_lblErrorText",">Unknown weapon vendor\nPossibly not supported")
		return false
	end
	if ra.isAssembledGun() then --if the pick-up slot is occupied
		widget.playSound("/sfx/interface/clickon_error.ogg")
		widget.setText("ra_PriceScrArea.ra_lblErrorText",">Output slot not empty")
		return false
	end
	if copySound or copyAltMode or ra.HasTrue(copyParts) then --any of the options requiring template is checked
		if not ra.isTemplateGun() or not ra.sametypeGuns() then --no template gun or gun type mismatch 
			widget.playSound("/sfx/interface/clickon_error.ogg")
			widget.setText("ra_PriceScrArea.ra_lblErrorText",">No template gun or gun type mismatch")
			return false
		end
	end
	
	--reading weapon Element
	local modgun = world.containerItemAt(pane.containerEntityId(), 0)
	local template = world.containerItemAt(pane.containerEntityId(), 1)
	local newElement
	SetElementOnce(modgun) --to ensure we have our weapon element done right we'll call this one more time
	--if the player changed the element manually but it was properly read at first during updateGui(), the marker IsSet is already true, so this should not be a problem... theoretically
	if widget.getSelectedOption("ra_radioElemental") ~= GetElementalIndex(modgun) then
	-- if the selected option does not match the current weapon element: remember the selected (new) one
		newElement = ra.elementalTypes[widget.getSelectedOption("ra_radioElemental")] --set TEXT (!) value
	else
		newElement = nil --otherwise: disregard it
	end
	
	--FINAL PRE-CHECK
	if not copySound and not copyAltMode and not ra.HasTrue(copyParts) and not ra.HasDye() and not newElement then --if no mod options (sound, AltMode, copyParts, newElement) are active and no dyes present
		widget.playSound("/sfx/interface/clickon_error.ogg")
		widget.setText("ra_PriceScrArea.ra_lblErrorText",">No mod options selected")
		return false
	end

	--FIRIN' UP--
	if copyAltMode then --AltMode check if it is modified
		for i = 1, #ra.altModeElemental do --check Elemental blacklist
			if (template.parameters.altAbilityType == ra.altModeElemental[i]) and ra.elementalTypes[widget.getSelectedOption("ra_radioElemental")] == "physical" then --if we copy elem-only mode over physical dmg
				widget.playSound("/sfx/interface/clickon_error_single.ogg")
				widget.setText("ra_PriceScrArea.ra_lblErrorText",">New altMode is\n locked to elemental")
				return false
			end
		end
	else --AltMode check if it stays the same but the element is modified instead
		for i = 1, #ra.altModeElemental do --check Elemental blacklist
			if (modgun.parameters.altAbilityType == ra.altModeElemental[i]) and ra.elementalTypes[widget.getSelectedOption("ra_radioElemental")] == "physical" then --if we try to set physical damage on a weapon with elem-only altMode
				widget.playSound("/sfx/interface/clickon_error_single.ogg")
				widget.setText("ra_PriceScrArea.ra_lblErrorText",">Current altMode is\n locked to elemental")
				return false
			end
		end
	end
	
	for i=1,3 do --to ensure we have our dyes we call this one more time. If the dyes didn't change since last preview redraw it should do nothing
		if not ra.sameDye(i) then --dye in slot i changed OR not-a-dye
			ra.updateDye(i) --if it is not a dye it just hides the number of variants
		end
	end
	
	--[[
	dyeSwaps proposed structure:
	part1name: paletteswap string
	part2name: paletteswap string
	part3name: paletteswap string
	]]
	
	--ra.reconstructGun(msg, something, copyParts, dyeSwaps, copySound, copyAltMode, newElement, newName)
	world.sendEntityMessage(pane.containerEntityId(), "reconstructGun", copyParts, nil, copySound, copyAltMode, newElement, nil)
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
	sb.logInfo("[HELP DUMP pal var]"..tostring(ra.palettes))
	for key,value in pairs(ra.palettes.dyeIndexes) do
		sb.logInfo("[HELP DUMP palettes.dyeIndexes]"..tostring(key).." : "..tostring(value))
	end
	
	--[[for key,value in pairs((world.containerItemAt(pane.containerEntityId(), 0))) do
		sb.logInfo("[HELP DUMP gun]"..key.." : "..tostring(value))
	end
	for key,value in pairs((world.containerItemAt(pane.containerEntityId(), 0)).parameters) do
		sb.logInfo("[HELP DUMP gun params]"..key.." : "..tostring(value))
	end
	

	for key,value in pairs(root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0)).config) do
		sb.logInfo("[HELP DUMP gun config]"..key.." : "..tostring(value))
	end
	for key,value in pairs(root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0)).config.altAbility) do
		sb.logInfo("[HELP DUMP gun config.altAbility]"..key.." : "..tostring(value))
	end
	for key,value in pairs(root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0)).config.altAbility.elementalConfig) do
		sb.logInfo("[HELP DUMP gun config.altAbility.elementalConfig]"..key.." : "..tostring(value))
	end]]
	
	--sb.logWarn("[PALETTE INDEX  ]"..dyeIndex)
	
	--local dyeIndex = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 3)).config.dyeColorIndex
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