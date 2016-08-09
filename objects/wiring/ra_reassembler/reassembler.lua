--require "/scripts/staticrandom.lua"
require "/scripts/util.lua"

ra = {}

function init()
	message.setHandler("scanGun", ra.scanGun)
	message.setHandler("renameGun", ra.renameGun)
	message.setHandler("reconstructGun", ra.reconstructGun)
	message.setHandler("resetGun", ra.resetGun)
end

function ra.scanGun(msg, something)
	if not world.containerItemAt(entity.id(), 0) then --if there is no gun
		return false
	end
	local modguncfg = root.itemConfig(world.containerItemAt(entity.id(), 0))
	local modgun = world.containerItemAt(entity.id(), 0)
	for key,value in pairs(modgun) do
		sb.logInfo("[HELP DUMP gun]"..key.." : "..tostring(value))
	end
	for key,value in pairs(modguncfg.config.fireSounds) do
		sb.logInfo("[HELP DUMP cfg.config]"..key.." : "..tostring(value))
	end
	return true
end

function ra.renameGun(msg, something, newName)
	if newName == "" or not world.containerItemAt(entity.id(), 0) then --if there is no new name or no gun
		return false
	end
	if world.containerItemAt(entity.id(), 0).name ~= "commonassaultrifle" or world.containerItemAt(entity.id(), 2) then --if not assault rifle or slot 3 is occupied
		return false
	end

	local item = world.containerTakeAt(entity.id(), 0) 
	item.parameters.shortdescription = newName
	for key,value in pairs(item) do
		sb.logInfo("[HELP DUMP ]"..key.." : "..tostring(value));
	end
	world.containerPutItemsAt(entity.id(), item, 2)
	return true
end

function ra.resetGun(msg, something)
	if not world.containerItemAt(entity.id(), 0) or world.containerItemAt(entity.id(), 2) then --if there is no gun or pickup slot is occupied
		return false
	end
	local modguncfg = root.itemConfig(world.containerItemAt(entity.id(), 0))

	local resetseed = modguncfg.parameters.seed
	local resetlevel = modguncfg.parameters.level
	local resetgun_template = world.containerItemAt(entity.id(), 0)
	--[[for key,value in pairs(resetgun_template) do
		if key ~= "count" and key ~= "name" then
			key=nil
		end
	end]]--
	resetgun_template.parameters = nil
	local resetgun = root.createItem(resetgun_template, resetlevel, resetseed)
	world.containerPutItemsAt(entity.id(), resetgun, 2)
	world.containerTakeAt(entity.id(), 0)
	return true
end

function ra.reconstructGun(msg, something, newName)
	if not world.containerItemAt(entity.id(), 0) or not world.containerItemAt(entity.id(), 1) or world.containerItemAt(entity.id(), 2) then --if there is no edited gun or no template or output slot is occupied
		return false
	end
	local modgun = world.containerItemAt(entity.id(), 0)
	local template = world.containerItemAt(entity.id(), 1)
	local templatecfg = root.itemConfig(world.containerItemAt(entity.id(), 1))
	--[[if modgun.name ~= template.name then --modgun.name ~= "commonassaultrifle" or modgun.name ~= template.name then --if not assault rifle or weapon type mismatch
		return false
	end--]]
	
	--[[for part,index in pairs(modgun.parameters.animationPartVariants) do
		sb.logInfo("[HELP DUMP item]"..part.." : "..tostring(index));
	end
	for part,index in pairs(template.parameters.animationPartVariants) do
		sb.logInfo("[HELP DUMP template]"..part.." : "..tostring(index));
	end]]--
	
	modgun.parameters.animationPartVariants = template.parameters.animationPartVariants
	--modgun.parameters.paletteSwaps = templatecfg.config.paletteSwaps
	--sb.logInfo("[HELP DUMP item]"..templatecfg.config.paletteSwaps);
	--[[for part,index in pairs(templatecfg.config.animationCustom) do
		sb.logInfo("[HELP DUMP templatecfg]"..part.." : "..tostring(index));
	end]]--
	construct(modgun.parameters, "animationCustom", "sounds", "fire")
	modgun.parameters.animationCustom.sounds.fire = templatecfg.config.animationCustom.sounds.fire
	
	world.containerPutItemsAt(entity.id(), modgun, 2)
	world.containerTakeAt(entity.id(), 0)
end
