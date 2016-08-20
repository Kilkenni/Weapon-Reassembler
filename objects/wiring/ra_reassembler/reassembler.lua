--require "/scripts/staticrandom.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

ra = {}

function init()
	message.setHandler("scanGun", ra.scanGun)
	message.setHandler("renameGun", ra.renameGun)
	message.setHandler("reconstructGun", ra.reconstructGun)
	message.setHandler("resetGun", ra.resetGun)
	message.setHandler("debugInfo", ra.debugInfo)
	self.weaponParts = {"butt","middle","barrel"} --1 - butt,2 - middle,3 - barrel
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
	for i,part in pairs(self.weaponParts) do --check gun parts
		if strname == part then
			return i --1 - butt, 2 - middle, 3 - barrel
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
	local nudefloran = "```````````````..```.`......`````````````.``,#:::;#........`......`````````\n`````````````````````......`````````````.'##+:#:::+..............``````````\n``````````````````````.....```````````,#;:;;::;+;:;:##.....`.....``````````\n```````````````````````.....`````````#;:::::::::'+;#::+.```.....```````````\n```````````````````````.....```````.#::::::;;++''+##;'+;```...`````````````\n````````````````````````....``````,+:::::;'':::;:::#+#:;```````````````````\n````````````````````````...``````,'::::;:'::::::::'::::++``````````````````\n..```````````````````````..`````;'::::;;'::::::::'';;::::#.```.````````````\n.`````````````````````......```#+;;;:;:+::::::::;;,#;;::::'````````````````\n.```````````````````````.....``.``##++#:::::::;;',,+:;:::::````````````````\n..``.```````````````````,+.``.````++;+,::::::;;+,,,##;:::::#```````````````\n....``````````````````.##+##``````;;++:::::::'#+''++:+;:::::.``````````````\n.....``````````````,##+@'#''`````#'+#:::::::'#:,,,,,#':;::::+``````````````\n......````````````+;''+#+#+#````.''++:::::;'':''###,;;+;::;:+``````````````\n......```````````''+###+#++;````'++#;::;;:#;,'@####,'++#';::'``````````````\n.....```````````.#'+#++#+++````.,;#;::;;#';,,++.##';:'###+;;;.`````````````\n....`.`````````,#''#++#+@``.```.`+';'##+;:,,,@###',,'';;;'#:;'`````````````\n....``````````+#''+####+##.````..#'+#'';,,,,,#';,,,:##;:;:#'#:`````````````\n....`````````'''''+++#++'+`````;':;'#;,,,,,,,,,,,,,;#+;:#;#`.`,````````````\n...``````````;'''##++++++',`````;##'+;,,,,,,,,,,,,:#:';:+:'.`....``````````\n.```````````#'''##+++###+'#`````::;##':,,,,,,,,,,,++:';;;,'.`...`;;``.`````\n```````````.#++#+++##+`;+'.``````#::'#;,;,,,,,,'::#;;'#;````.....##,,.`````\n``````````:':###++#++@'#+@````.```,+;:'###+;+,;;+:;#:;'+````....``.`+;,````\n`````````.;#;';#+##++###+#````````#'++#,##+#:;,+###::#..```......`````,````\n````````,'+;+'''`++++++'#@`````````'#'';,,,;,+####:+';@.```....`##;+,.#@```\n````````###;'@+```#+++##'@``````.`#;;'+#,,'@+::#####@+.````...``#@+#:';;.,`\n```````@'';#+;#```.`,.`@+@`````````,#;+##;:;;:#;#'';;'#.``;+',..;``````````\n``````''''++;;#````````###`````::;``.+:'+###@';#+';+':,...`........`.``````\n``````+''''+###.````.``#+#``'#''''+``,;#;;'':'#@'';;'...............```````\n.````';''+''++#`+.@#@#@+#'##;;;;;''#+###+####+'@;;#;;'..............````.``\n.````+;''+''++##:#:#'#+###++''''++#'#''#'''#'##'.;'.``..............```````\n..``:''''#++++##;#;##+'+##+''#';;''#'##+'''#'+#'+.``................```````\n.```@;'''#+++++#;#;#+#++##+##'';;'######'''#'''#+#####,............````````\n````+''''+++++##+###''++##;#'''''###'++#'''''#''###'''##...........`..``.``\n.```+''''+++++#####'+'#+##++#''++''+'+#''''+'+##+#++#+'+#.............`````\n```+''''#++++#''#++#''###'#'+#++'''''##+++####+++#';''#''#.............````\n```@'''+'++++++#+'++'###+'#''+#'';'''##++;';'''#+#;;;'#''#,...........`````\n````#++''++#++#''+#''###+++###';;;'''#';';;;'''#'#'';;''''#.............```\n````.#@@@##@:#''++#+'++######'';;;'+';';;;;;'''#'#'';'''''@.............```\n````````````@''+'#''##+#..#+;'';;''+#+';;;;;'''+'#+'''''''@............````\n``````````+#@'''+#+'#@+#.#;';';'''#++';;';;''''+'#'+''''''#............``.`\n``````.```#+''''#;'++++'#;;;;;;'''##;;;;::;''''++#++++''''+:.............``\n``````,+`#'+'''++'''+++#'';;;;;'''#;;;;'';;:''++###'+''''''#@............`.\n```@``#';''''''+'''+#+#+''';;;;''''';;;;:;'''''#+###'+'+'+@:+;.............\n``.;''''''''''#'''++###+'';;;;'''#';;;;'';;''''#+###++'#+@';@;:............\n``.`+'''''''+#+'''++++##+''';'''+#';;;;;;;;''''#####+'###+'@;;@@...........\n..`#'''''''+++'''+++++##++''''''#+'';;;'';'''''##+@###'+'#@;;#:;+..........\n``;'''''''+++''''++##++++++'''++#+'';;'+;;#'''+#+##,##+'###;@''#;#.........\n.`#'''''+'++''''+++##++##+++++++#++''''+##'''+#++#,,,@+'+##@#;#;'+@........\n`++';'+'++++''''++###+#+;#+++++++'+'''''''''++###:,,,,##''####;;@:#@.......\n``,''#+++++''''+'+##+;+#.,###'';+''++'+++++++#+#',,,,,,#+''##@##;##':......\n,'''#+++++''''++'+'#+@....#'#'';';''++++++++###@,,,,,,,,@+#'+#'#+@;#;......\n',###'++'+;'''+''#'+#;:...''+'';';;'''#########,,,,,,,,,,@#;'+#+###+#......\n..#.`'++'#'''+'''@;,+.....;'''';'';;;'''##++###,,,,,,,,,,,#+''####++#@'....\n``.`.:+;'''''''@@.`.+..``.,'''';''''''''''++##@,,,,,,,,,,,,#++#++++@@##;...\n.``,''@''''''+##.......``..++'';''''''''++++##:,,,,,,,,,,,,,;#+++@@@'+++,.,\n.`';;'';''''+'+`.....```...##'''#'''''''#+++#@,,,,,,,,,,,,,,,,#+@+'+'+'+#.,\n`.'...,'''''+'`....`````...#''''#''''''#'++##,,,,,,,,,,,,,,,,,,@++'+'++++;,\n.....:;,'''+'#+....`````...:'#''+;'''''++++#+,,,,,,,,,,,,,,,,,,@+';#'++++#,\n`.....``'''+'#+....````.....#+;'#'''''#+++++,,,,,,,,,,,,,,,,,,,@+;;#'++++;,\n........'''''++...```..``...#;''+#'''++++#+#,,,,,,,,,,,,,,,,,,,@'''#''+++,,\n........;'''':#...````.`...++#'#:'''+++''+++',,,,,,,,,,,,,,,,,.#'''@'++++.,\n........''''''.,,.,`......,##'#;;:#''''+'##+#,,,,,,,,,,,,,,,,,.++''+'+++#.,\n.......;`''#':,,,,,,.,....####::;:+'''#'+'#++#;,,,,,,,,,,,,,,,,++;'''+++@,,\n"
	--this is a magic string, don't touch it. The author can be found on guoh-art.tumblr.com. Go hug him.
	sb.logInfo(nudefloran)
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
		sb.logInfo("[HELP DUMP cfg.config.invIcon]"..key.." : "..tostring(value))
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

function ra.reconstructGun(msg, something, copyParts, copySound, copyAltMode, newName)
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
		modgun.parameters.animationParts = modgun.parameters.animationParts or {} --create structure
		local copyfrom = templatecfg.config.animationParts --CHANGE here for separate parts
		if template.parameters.animationParts then --template has custom graphics already
			copyfrom = template.parameters.animationParts
		end
					
		for k, v in pairs(copyfrom) do --iterate on weapon parts
			if isWeaponPart(k) then --if it IS indeed a weapon part (there's also a muzzle flash there!)
				if copyParts[isWeaponPart(k)] then --if we need to copy that part
					modgun.parameters.animationParts[k] = ra.getAbsImage(v) --copy with default color
				else --if we don't need it, we still need to copy the existing from config or the game crashes
					modgun.parameters.animationParts[k] = ra.getAbsImage(modguncfg.config.animationParts[k])
				end
				if modguncfg.config.paletteSwaps then --if own palette exists
					modgun.parameters.animationParts[k] = modgun.parameters.animationParts[k] .. modguncfg.config.paletteSwaps -- + apply own palette
				end
			end			
		end
		for part,value in pairs(template.parameters.animationPartVariants) do --copy indexes to calc size correctly
			if copyParts[isWeaponPart(part)] then --if we need to copy that part
				modgun.parameters.animationPartVariants[part] = value
			end --we don't need to copy existing ones as they always exist even for vanilla guns
		end

		copyfrom = templatecfg.config.inventoryIcon --first copy config
		if template.parameters.inventoryIcon then --template has custom icon - copy it instead
			copyfrom = template.parameters.inventoryIcon
		end
		
		modgun.parameters.inventoryIcon = modgun.parameters.inventoryIcon or {} --create structure
		local imageOffset = {0,0}
		for key, value in pairs(modguncfg.config.inventoryIcon) do
			if copyParts[key] then --if we need to copy that part
				modgun.parameters.inventoryIcon[key] = copyfrom[key]
			else --if we don't, copy it from config to preserve full structure and save game from going bonkers
				modgun.parameters.inventoryIcon[key] = modguncfg.config.inventoryIcon[key]
			end
			local imageSize = root.imageSize(modgun.parameters.inventoryIcon[key].image)
			imageOffset = vec2.add(imageOffset, {imageSize[1] / 2, 0}) --add half image width
			modgun.parameters.inventoryIcon[key].position = imageOffset --set part position
			imageOffset = vec2.add(imageOffset, {imageSize[1] / 2, 0}) --add another half image width
			if modguncfg.config.paletteSwaps then --if own palette exists (we already have a pic at this step)
				modgun.parameters.inventoryIcon[key].image = ra.getAbsImage(modgun.parameters.inventoryIcon[key].image) .. modguncfg.config.paletteSwaps -- + apply own palette
			end
		end
		
		--modgun.parameters.inventoryIcon = copyfrom --COPY icon
		
	end
	
	if copySound and templatecfg ~=0 then --copy fire sound
		construct(modgun.parameters, "animationCustom", "sounds", "fire")
		if template.parameters and template.parameters.animationCustom and template.parameters.animationCustom.sounds and template.parameters.animationCustom.sounds.fire then
			modgun.parameters.animationCustom.sounds.fire = template.parameters.animationCustom.sounds.fire
		else --template has no custom sound, copy from  config
			modgun.parameters.animationCustom.sounds.fire = templatecfg.config.animationCustom.sounds.fire
		end
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