ra = {}

function init()
	ra.locked = false
	message.setHandler("selectHue", function(arg1, arg2, hue) selectHue(hue) end)
	message.setHandler("renameGun", ra.renameGun)
	message.setHandler("reconstructGun", ra.reconstructGun)
	message.setHandler("resetGun", ra.resetGun)
end

function selectHue(hue)
	if world.containerItemAt(entity.id(), 0) and root.itemConfig(world.containerItemAt(entity.id(), 0)).config.materialId then
		local item = world.containerTakeAt(entity.id(), 0) -- pick the item that was added
		item.parameters.materialHueShift = hue
		world.containerPutItemsAt(entity.id(), item, 0)
	end
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
end

function ra.resetGun(msg, something)
	if not world.containerItemAt(entity.id(), 0) then --if there is no gun
		return false
	end
	local modgun = root.itemConfig(world.containerItemAt(entity.id(), 0))
	for key,value in pairs(modgun) do
		sb.logInfo("[HELP DUMP ]"..key.." : "..tostring(value))
	end
	if modgun.config then
	sb.logInfo("[HELP DUMP ] CONFIG")
		for key,value in pairs(modgun.config) do
			sb.logInfo("[HELP DUMP ]"..key.." : "..tostring(value))
		end
	end
	local resetseed = modgun.parameters.seed
	local resetlevel = modgun.parameters.level
	local resetgun_template = world.containerItemAt(entity.id(), 0)
	--[[for key,value in pairs(resetgun_template) do
		if key ~= "count" and key ~= "name" then
			key=nil
		end
	end]]--
	resetgun_template.parameters = nil
	local resetgun = root.createItem(resetgun_template, resetlevel, resetseed)
	for key,value in pairs(resetgun) do
		sb.logInfo("[HELP DUMP ] resetgun "..key.." : "..tostring(value))
	end
	world.containerPutItemsAt(entity.id(), resetgun, 2)
	--[[if newName == "" or not world.containerItemAt(entity.id(), 0) then --if there is no new name or no gun
		return false
	end
	if world.containerItemAt(entity.id(), 0).name ~= "commonassaultrifle" or world.containerItemAt(entity.id(), 2) then --if not assault rifle or slot 3 is occupied
		return false
	end
	local item = world.containerTakeAt(entity.id(), 0) 
	item.parameters.shortdescription = newName
	world.containerPutItemsAt(entity.id(), item, 2)]]--
end

function ra.reconstructGun(msg, something, newName)
	if not world.containerItemAt(entity.id(), 0) or not world.containerItemAt(entity.id(), 1) or world.containerItemAt(entity.id(), 2) then --if there is no edited gun or no template or output slot is occupied
		return false
	end
	local modgun = world.containerTakeAt(entity.id(), 0)
	local template = world.containerItemAt(entity.id(), 1)
	if world.containerItemAt(entity.id(), 0).name ~= "commonassaultrifle" or world.containerItemAt(entity.id(), 0).name ~= world.containerItemAt(entity.id(), 1).name then --if not assault rifle or weapon type mismatch
		return false
	end
	
	--[[for part,index in pairs(modgun.parameters.animationPartVariants) do
		sb.logInfo("[HELP DUMP item]"..part.." : "..tostring(index));
	end
	for part,index in pairs(template.parameters.animationPartVariants) do
		sb.logInfo("[HELP DUMP template]"..part.." : "..tostring(index));
	end]]--
	
	modgun.parameters.animationPartVariants = template.parameters.animationPartVariants
	
	world.containerPutItemsAt(entity.id(), item, 2)
end
