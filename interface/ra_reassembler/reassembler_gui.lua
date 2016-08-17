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
	self.gunImageZero = {40,85}

	self.highlightPulseTimer = 0
	updateGui()
	
	ra.acceptableGun = {"commonpistol","uncommonpistol","rarepistol","commonmachinepistol","uncommonmachinepistol","raremachinepistol","commonassaultrifle","uncommonassaultrifle","rareassaultrifle","commonsniperrifle","uncommonsniperrifle","raresniperrifle","commonshotgun","uncommonshotgun","rareshotgun","commongrenadelauncher","uncommongrenadelauncher","raregrenadelauncher","commonrocketlauncher","uncommonrocketlauncher","rarerocketlauncher"}

	ra.acceptableGunType = {"pistol","machinepistol","assaultrifle","sniperrifle","shotgun","grenadelauncher","rocketlauncher"}
	ra.rarityTiers = {"common","uncommon","rare","legendary"}
	ra.craftedTiers = {"iron", "tungsten", "titanium", "durasteel", "aegisalt", "violium", "ferozium"}
	ra.altModeElemental =  {"lance", "explosiveburst"} --those abilities are elemental-only
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
		
		local scale = 2
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
			if modguncfg.config.paletteSwaps then --if native palette exists - recolor accordingly
				for i,part in ipairs(gunimage) do
					part.image = ra.getAbsImage(part.image) .. modguncfg.config.paletteSwaps
				end
			end
		end
		--Drawing preview
		for i,part in ipairs(gunimage) do --iterate over gunimage array
			local imgWidget = "ra_gunImage"..tostring(i) --get widget name
			widget.setImage(imgWidget,part.image)
			widget.setImageScale(imgWidget,scale)
			part.position = { root.imageSize(part.image)[1], 0} --calculate size from image part (only X)
			local imgpos = {0,0}
			for j=2,i do
				imgpos = vec2.add(imgpos,gunimage[j-1].position) --sum all previous image parts' sizes
			end
			widget.setPosition(imgWidget, vec2.add(self.gunImageZero, vec2.mul(imgpos,scale))) --shift images
		end
		--[[
		local image1size = { root.imageSize(gunimage[1].image)[1], 0}
		widget.setImage("ra_gunImage1",gunimage[1].image)
		widget.setImageScale("ra_gunImage1",scale)
		
		local image2size = { root.imageSize(gunimage[2].image)[1], 0}
		widget.setImage("ra_gunImage2",gunimage[2].image)
		widget.setImageScale("ra_gunImage2",scale)
		widget.setPosition("ra_gunImage2",vec2.add(self.gunImageZero, vec2.mul(image1size,scale)))
		
		widget.setImage("ra_gunImage3",gunimage[3].image)
		widget.setImageScale("ra_gunImage3",scale)
		widget.setPosition("ra_gunImage3",vec2.add(self.gunImageZero, vec2.mul(vec2.add(image1size,image2size), scale)))
		--]]
	else
		widget.setImage("ra_gunImage1","")
		widget.setImage("ra_gunImage2","")
		widget.setImage("ra_gunImage3","")
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
	local guntype =  ra.getWeaponType(world.containerItemAt(pane.containerEntityId(), itemindex).name) --get weapon type
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
		modguncfg = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0))
		template = world.containerItemAt(pane.containerEntityId(), 1)
		for i = 1, #ra.altModeElemental do --check Elemental blacklist
			if(ra.altModeElemental[i] == template.parameters.altAbilityType) and modguncfg.config.elementalType == "physical" then --if we copy elem-only mode over physical dmg
				widget.playSound("/sfx/interface/clickon_error_single.ogg")
				return false
			end
		end
	end
	world.sendEntityMessage(pane.containerEntityId(), "reconstructGun", copySound, copyAltMode)
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
			widget.playSound("/sfx/objects/cropshipper_box_lock3.ogg")
			world.sendEntityMessage(pane.containerEntityId(), "resetGun")
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

function ra.debugButton(widgetName)
	--world.sendEntityMessage(pane.containerEntityId(), "debugInfo")
	widget.setVisible("ra_lblDebug", true)
	--[[
	for key,value in pairs(deb) do
		sb.logWarn("[HELP WIDGET ]"..key.." : "..tostring(value))
	end--]]
	--sb.logWarn("[HELP WIDGET ]"..tostring(deb))
	--[[
	if ra.isModGun() and ra.goodGun(0) then
		local modguncfg = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0)).config
		if world.containerItemAt(pane.containerEntityId(), 0).parameters.inventoryIcon then
			modguncfg = world.containerItemAt(pane.containerEntityId(), 0).parameters
		end		
		local scale = 2
		local image1size = { root.imageSize(modguncfg.inventoryIcon[1].image)[1], 0}
		widget.setImage("ra_gunImage1",modguncfg.inventoryIcon[1].image)
		widget.setImageScale("ra_gunImage1",scale)
		
		local image2size = { root.imageSize(modguncfg.inventoryIcon[2].image)[1], 0}
		widget.setImage("ra_gunImage2",modguncfg.inventoryIcon[2].image)
		widget.setImageScale("ra_gunImage2",scale)
		widget.setPosition("ra_gunImage2",vec2.add(self.gunImageZero, vec2.mul(image1size,scale)))
		
		widget.setImage("ra_gunImage3",modguncfg.inventoryIcon[3].image)
		widget.setImageScale("ra_gunImage3",scale)
		widget.setPosition("ra_gunImage3",vec2.add(self.gunImageZero, vec2.mul(vec2.add(image1size,image2size), scale)))		
	end
	--]]
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
		
		local scale = 2
		local gunimage = modgun.parameters.inventoryIcon --try copy gun's icon images
		if not gunimage then --if there are none grab them from config
			gunimage = modguncfg.config.inventoryIcon
		end
		if templategun then --if we have a good template gun as well
			gunimage = templategun.parameters.inventoryIcon --REAPLCE THIS WITH SEPARATE PARTS COPY
			if not gunimage then --if there are noimages in the tempalte gun itself
				gunimage = templateguncfg.config.inventoryIcon
			end
		end
			
		local image1size = { root.imageSize(gunimage[1].image)[1], 0}
		widget.setImage("ra_gunImage1",gunimage[1].image)
		widget.setImageScale("ra_gunImage1",scale)
		
		local image2size = { root.imageSize(gunimage[2].image)[1], 0}
		widget.setImage("ra_gunImage2",gunimage[2].image)
		widget.setImageScale("ra_gunImage2",scale)
		widget.setPosition("ra_gunImage2",vec2.add(self.gunImageZero, vec2.mul(image1size,scale)))
		
		widget.setImage("ra_gunImage3",gunimage[3].image)
		widget.setImageScale("ra_gunImage3",scale)
		widget.setPosition("ra_gunImage3",vec2.add(self.gunImageZero, vec2.mul(vec2.add(image1size,image2size), scale)))
	end
	--]]
	
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