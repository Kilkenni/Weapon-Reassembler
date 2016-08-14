--require "/scripts/staticrandom.lua"
require "/scripts/util.lua"

ra = {}

function init()
	message.setHandler("scanGun", ra.scanGun)
	message.setHandler("renameGun", ra.renameGun)
	message.setHandler("reconstructGun", ra.reconstructGun)
	message.setHandler("resetGun", ra.resetGun)
	message.setHandler("debugInfo", ra.debugInfo)
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
		sb.logInfo("[HELP DUMP cfg.config.animationParts]"..key.." : "..tostring(value))
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

function ra.reconstructGun(msg, something, copySound, copyAltMode, newName)
	if not world.containerItemAt(entity.id(), 0) or not world.containerItemAt(entity.id(), 1) or world.containerItemAt(entity.id(), 2) then --if there is no edited gun or no template or output slot is occupied
		return false
	end
	local modgun = world.containerItemAt(entity.id(), 0)
	local template = world.containerItemAt(entity.id(), 1)
	local templatecfg = 0
	
	if template then --copy graphics
		templatecfg = root.itemConfig(world.containerItemAt(entity.id(), 1))
		modgun.parameters.animationPartVariants = template.parameters.animationPartVariants
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