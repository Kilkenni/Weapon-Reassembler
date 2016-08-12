require "/scripts/util.lua"
ra = {}
ra.acceptableGun = {"commonpistol","uncommonpistol","rarepistol","commonmachinepistol","uncommonmachinepistol","raremachinepistol","commonassaultrifle","uncommonassaultrifle","rareassaultrifle","commonsniperrifle","uncommonsniperrifle","raresniperrifle","commonshotgun","uncommonshotgun","rareshotgun","commongrenadelauncher","uncommongrenadelauncher","raregrenadelauncher","commonrocketlauncher","uncommonrocketlauncher","rarerocketlauncher"}

ra.acceptableGunType = {"pistol","machinepistol","assaultrifle","sniperrifle","shotgun","grenadelauncher","rocketlauncher"}

function init()
	ra.renameVisible = false
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
	
	local result = world.sendEntityMessage(pane.containerEntityId(), "reconstructGun")
	widget.playSound("/sfx/objects/penguin_welding4.ogg")
end

function ra.resetButton(widgetName)
	if not ra.isModGun() or ra.isAssembledGun() or not ra.goodGun(0) then --if there is no gun or pick-up slot is occupied, or the gun is not "good"
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	world.sendEntityMessage(pane.containerEntityId(), "resetGun")
	widget.playSound("/sfx/objects/cropshipper_box_lock3.ogg")
end

function ra.scanButton(widgetName)
	if not ra.isModGun() or not ra.goodGun(0) then --if there is no gun or the item is not a good gun
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	world.sendEntityMessage(pane.containerEntityId(), "scanGun")
	local modguncfg = root.itemConfig(world.containerItemAt(pane.containerEntityId(), 0))
	widget.setImage("ra_gunImage",modguncfg.parameters.animationParts.butt) 
	widget.playSound("/sfx/interface/scan.ogg")
end

function ra.debugButton(widgetName)
	world.sendEntityMessage(pane.containerEntityId(), "debugInfo")
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