--require "/scripts/staticrandom.lua"
require "/scripts/util.lua"

ra = {}

function init()
	message.setHandler("scanGun", ra.scanGun)
	message.setHandler("renameGun", ra.renameGun)
	message.setHandler("reconstructGun", ra.reconstructGun)
	message.setHandler("resetGun", ra.resetGun)
	message.setHandler("debugInfo", ra.debugInfo)
	self.weaponParts = {"barrel","middle","butt"}
	self.palettes = { --dyes dyeColorIndex
		"", --1 dye remover
		"", --1 black
		"", --3 grey
		"", --4 white
		"", --5 red
		"", --6 orange
		"", --7 yellow
		"", --8 green
		"", --9 blue
		"", --10 purple
		"", --11 pink
		"" --12 brown
	}
end

function isWeaponPart(strname) --checks if a string matches any known weapon part
	for _,part in pairs(self.weaponParts) do
		if strname == part then
			return true
		end
	end
	return false
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
	for key,value in pairs(modguncfg.config) do
		sb.logInfo("[HELP DUMP cfg.config]"..key.." : "..tostring(value))
	end
	for key,value in pairs(modguncfg.config.animationParts) do
		sb.logInfo("[HELP DUMP cfg.config.animParts]"..key.." : "..tostring(value))
	end
	for key,value in pairs(modguncfg.config.inventoryIcon) do
		sb.logInfo("[HELP DUMP cfg.config.invIcon.pos]"..key.." : "..tostring(value.position))
	end
	for key,value in pairs(modgun.parameters) do
		sb.logInfo("[HELP DUMP gun.params]"..key.." : "..tostring(value))
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

	local modgun = world.containerTakeAt(entity.id(), 0) 
	modgun.parameters.shortdescription = newName
	modgun.parameters.tooltipKind = "ra_guncustom"
	world.containerPutItemsAt(entity.id(), modgun, 2)
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

function ra.getDirImg(path) --removes image from the path, leaving only instructions
	if not path or type(path) ~= "string" then
		return false
	end
	local i,j = string.find(path, "?") --get first index of instructions
	if i then
		return string.sub(path,i,-1) --return the path without the image
	else
		return false
	end
end

function ra.reconstructGun(msg, something, copySound, copyAltMode, newName)
	if not world.containerItemAt(entity.id(), 0) or not world.containerItemAt(entity.id(), 1) or world.containerItemAt(entity.id(), 2) then --if there is no edited gun or no template or output slot is occupied
		return false
	end
	local modgun = world.containerItemAt(entity.id(), 0)
	local modguncfg = root.itemConfig(modgun)
	local template = world.containerItemAt(entity.id(), 1)
	local templatecfg = 0
	
	if template then --copy graphics
		templatecfg = root.itemConfig(world.containerItemAt(entity.id(), 1))
		--modgun.parameters.animationPartVariants = template.parameters.animationPartVariants
		modgun.parameters.animationParts = modgun.parameters.animationParts or {} --COPY weapon visuals
		for k, v in pairs(templatecfg.config.animationParts) do --iterate on weapon parts
			if isWeaponPart(k) then --if it IS indeed a weapon part
				if modguncfg.config.paletteSwaps then --if own palette exists
					modgun.parameters.animationParts[k] = ra.getAbsImage(v) .. modguncfg.config.paletteSwaps --copy part path + apply own palette
				else
					modgun.parameters.animationParts[k] = ra.getAbsImage(v) --else copy with default color
				end
			end			
		end
		
		modgun.parameters.inventoryIcon = templatecfg.config.inventoryIcon --COPY icon
		if modguncfg.config.paletteSwaps then --if own palette exists
			for k, v in pairs(modgun.parameters.inventoryIcon) do --iterate on icon parts
				modgun.parameters.inventoryIcon[k].image = ra.getAbsImage(v.image) .. modguncfg.config.paletteSwaps --copy part path + apply own palette
			end
		end
	end
	
	if copySound and templatecfg ~=0 then --copy fire sound
		construct(modgun.parameters, "animationCustom", "sounds", "fire")
		modgun.parameters.animationCustom.sounds.fire = templatecfg.config.animationCustom.sounds.fire
	end
	if copyAltMode and modgun.parameters.altAbilityType and template.parameters.altAbilityType then --copy Alternative Fire mode (weapon types checked in GUI)
		modgun.parameters.altAbilityType = template.parameters.altAbilityType
	end
	if newName then --if renaming
		--TODO - copy renaming func here
	end
	modgun.parameters.tooltipKind = "ra_guncustom" --assigning alt tooltip with "Custom" label
	
	world.containerPutItemsAt(entity.id(), modgun, 2)
	world.containerTakeAt(entity.id(), 0)
end

--DEBUG LOG PRINT FUNCTIONS
local function tableLen(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

--Required for printTable
local function getValueOutput(key ,value)
    if type(value) == "table" then
        return "table : "..key;
    elseif type(value) == "function" then
        return "function : "..key.."()"
    elseif type(value) == "string" then
        return "string : "..key.." - \""..tostring(value).."\"";
    else
        return type(value).." : "..key.." - "..tostring(value);
    end
end

function ra.debugInfo(msg, something)
	local indent = 0
	local value = sb
	local tabs = ""
    for i=1,indent,1 do
        tabs = tabs.."    "
    end
    table.sort(value)
    for k,v in pairs(value) do
        sb.logInfo(tabs..getValueOutput(k,v))
        if type(v) == "table" then
            if tostring(k) == "utf8" then
                sb.logInfo("    "..tabs.."SKIPPING UTF8 SINCE IT SEEMS TO HAVE NO END AND JUST BE FILLED WITH TABLES OF TABLES")
            else
                if tableLen(v) == 0 then
                    sb.logInfo("    "..tabs.."EMPTY TABLE")
                else
                    printTable(indent+1,v)
                  
                end
            end
            sb.logInfo(" ")
        end
    end 
end