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
	if newName == "" then
		local default = root.itemConfig(object.name())
		newName = default.config.shortdescription
	end
	object.setConfigParameter("shortdescription", newName)
end
