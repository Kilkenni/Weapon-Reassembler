require "/scripts/util.lua"
ra = {}

function init()
	ra.renameVisible = false
end

function ra.testCallback(widgetName)
	widget.playSound("/sfx/tools/pickaxe_precious.ogg")
end

function ra.renameButton(widgetName)
  ra.renameVisible = not ra.renameVisible
  widget.setVisible("ra_boxRename", ra.renameVisible)
  widget.focus( ra.renameVisible and "ra_boxRename" or "ra_btnRename" )
end

function ra.reconstructButton(widgetName)
	world.sendEntityMessage(pane.containerEntityId(), "reconstructGun")
end

function ra.resetButton(widgetName)
	world.sendEntityMessage(pane.containerEntityId(), "resetGun")
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