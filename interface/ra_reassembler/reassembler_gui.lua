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
	self.gunImageZero = {30,115}

	self.highlightPulseTimer = 0
	updateGui()
	
	ra.acceptableGun = {"commonpistol","uncommonpistol","rarepistol","commonmachinepistol","uncommonmachinepistol","raremachinepistol","commonassaultrifle","uncommonassaultrifle","rareassaultrifle","commonsniperrifle","uncommonsniperrifle","raresniperrifle","commonshotgun","uncommonshotgun","rareshotgun","commongrenadelauncher","uncommongrenadelauncher","raregrenadelauncher","commonrocketlauncher","uncommonrocketlauncher","rarerocketlauncher"}

	ra.acceptableGunType = {"pistol","machinepistol","assaultrifle","sniperrifle","shotgun","grenadelauncher","rocketlauncher"}
	ra.rarityTiers = {"common","uncommon","rare","legendary"}
	ra.craftedTiers = {"iron", "tungsten", "titanium", "durasteel", "aegisalt", "violium", "ferozium"}
	ra.altModeElemental =  {"lance", "explosiveburst"} --those abilities are elemental-only
end

function updateGui()
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
	for i,goodtype in ipairs(ra.acceptableGunType) do
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
	local deb =  ra_itemIcon
	--[[
	for key,value in pairs(deb) do
		sb.logWarn("[HELP WIDGET ]"..key.." : "..tostring(value))
	end--]]
	--sb.logWarn("[HELP WIDGET ]"..tostring(deb))
	if ra.isModGun() and ra.goodGun(0) then
		local modguncfg = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0)).config
		if world.containerItemAt(pane.containerEntityId(), 0).parameters.inventoryIcon then
			modguncfg = world.containerItemAt(pane.containerEntityId(), 0).parameters
		end
		--local butt = ra.getAbsImage(modguncfg.animationParts.butt)
		--local middle = ra.getAbsImage(modguncfg.animationParts.middle)
		--local i, j = string.find()
		--local tempdir = string.
		--[[
		local imagepath = ra.getAbsImage(modguncfg.animationParts.butt) .. "?blend=" .. ra.getAbsImage(modguncfg.animationParts.middle) .. ";13;0"
		--]]
		
		local scale = 2
		local imagezero = {40,120}
		local image1pos = { root.imageSize(modguncfg.inventoryIcon[1].image)[1], 0}
		--modguncfg.inventoryIcon[1].position
		widget.setImage("ra_gunImage1",modguncfg.inventoryIcon[1].image)
		widget.setImageScale("ra_gunImage1",scale)
		--widget.setPosition("ra_gunImage1",vec2.add(self.gunImageZero, vec2.mul(image1pos,scale)))
		
		local image2pos = { root.imageSize(modguncfg.inventoryIcon[2].image)[1], 0}
		--modguncfg.inventoryIcon[2].position
		widget.setImage("ra_gunImage2",modguncfg.inventoryIcon[2].image)
		widget.setImageScale("ra_gunImage2",scale)
		widget.setPosition("ra_gunImage2",vec2.add(self.gunImageZero, vec2.mul(image1pos,scale)))
		
		--local image3pos = { root.imageSize(modguncfg.inventoryIcon[3].image)[1], 0}
		--modguncfg.inventoryIcon[3].position
		widget.setImage("ra_gunImage3",modguncfg.inventoryIcon[3].image)
		widget.setImageScale("ra_gunImage3",scale)
		widget.setPosition("ra_gunImage3",vec2.add(self.gunImageZero, vec2.add(vec2.mul(image1pos,scale),vec2.mul(image2pos,scale))))
		
	end
	
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