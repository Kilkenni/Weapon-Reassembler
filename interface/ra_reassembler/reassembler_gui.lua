require "/scripts/util.lua"
ra = {}

function init()
	ra.renameVisible = false
end

function ra.renameButton(widgetName)
  ra.renameVisible = not ic.renameVisible
  widget.setVisible("ra_boxRename", ic.renameVisible)
  widget.focus( ra.renameVisible and "ra_boxRename" or "ra_btnRename" )
end

function ra.renameThis(widgetName)
  ra.renameVisible = false
  widget.setVisible("ra_boxRename", false)
  widget.focus("ra_btnRename")
  local newName = widget.getText("ra_boxRename")
  if newName then
	world.sendEntityMessage(pane.containerEntityId(), "renameThing", newName)
  end
end