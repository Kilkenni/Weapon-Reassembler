require "/scripts/util.lua"
ra = {}

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
	local result = world.sendEntityMessage(pane.containerEntityId(), "reconstructGun")
	widget.playSound("/sfx/interface/penguin_welding4.ogg")
end

function ra.resetButton(widgetName)
	if not ra.isModGun() or ra.isAssembledGun() then --if there is no gun or pick-up slot is occupied
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	world.sendEntityMessage(pane.containerEntityId(), "resetGun")
	widget.playSound("/sfx/interface/ship_confirm1.ogg")
end

function ra.scanButton(widgetName)
	if not ra.isModGun() then --if there is no gun
		widget.playSound("/sfx/interface/clickon_error.ogg")
		return false
	end
	world.sendEntityMessage(pane.containerEntityId(), "scanGun")
	widget.playSound("/sfx/objects/castleswitchon.ogg")
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