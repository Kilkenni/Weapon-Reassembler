ra = {}

function init()
	ra.locked = false
	message.setHandler("selectHue", function(arg1, arg2, hue) selectHue(hue) end)
	message.setHandler("renameThing", ra.renameItem)
end

function selectHue(hue)
	if world.containerItemAt(entity.id(), 0) and root.itemConfig(world.containerItemAt(entity.id(), 0)).config.materialId then
		local item = world.containerTakeAt(entity.id(), 0) -- pick the item that was added
		item.parameters.materialHueShift = hue
		world.containerPutItemsAt(entity.id(), item, 0)
	end
end

function ra.renameItem(msg, something, newName)
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
