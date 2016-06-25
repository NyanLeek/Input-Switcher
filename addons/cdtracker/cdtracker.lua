local acutil = require('acutil');
settings = {}
local default = {
	checkVal = 5;
	alerts = 1;
	sound = 1;
	text = 1;
	soundtype = 1;
	icon = 1;
	ignoreList = {};
	chatList = {};
	shout = {}
	}

local skillName = ' '
local fullName = ' '
local prevName = ' '
local cdCheck = settings.checkVal
local curTime = 0
local totalTime = 0
local obj = nil
local counter = 0
local offset = 0
local queue = {}
local oldVal = {}
local skillCd = {}
local skillList = {}
skillFrame = {}
iconFrame = {}
iconSlots = {}
soundTypes = {'button_click_stats_up','quest_count','quest_event_start','quest_success_2','sys_alarm_mon_kill_count','quest_event_click','sys_secret_alarm', 'travel_diary_1','button_click_4'}

local timer = imcTime.GetAppTime()
local msgDisplay = 0

local screenWidth = ui.GetClientInitialWidth();
local screenHeight = ui.GetClientInitialHeight();

function cdTracker_LoadSettings()
	local s, err = acutil.loadJSON("../addons/cdtracker/settings.json");
	if err then
		settings = default
	else
		settings = s
		for k,v in pairs(default) do
			if not s[k] then
				settings[k] = v
			end
		end
	end
	cdTracker_SaveSettings()
end

function cdTracker_SaveSettings()
	table.sort(settings)
	acutil.saveJSON("../addons/cdtracker/settings.json", settings);
end

function cdTracker_SetVal(command)
	local cmd = table.remove(command,1);
	if (type(tonumber(cmd)) == "number") then
		settings.checkVal = tonumber(cmd)
		cdTracker_SaveSettings()
		cdTracker_LoadSettings()
		return CHAT_SYSTEM('CD alert set to '..cmd..' seconds.')
	end
	if (cmd == 'on') then
		settings.alerts = 1
		cdTracker_SaveSettings()
		cdTracker_LoadSettings()
		return CHAT_SYSTEM('CD alerts on.');
		end
	if (cmd == 'off') then
		settings.alerts = 0
		cdTracker_SaveSettings()
		cdTracker_LoadSettings()
		return CHAT_SYSTEM('CD alerts off.')
	end
	if (cmd == 'sound') then
		local soundVal = table.remove(command,1)
		if soundVal ~= nil then
			if type(tonumber(soundVal)) == 'number' then
				settings.soundtype = math.floor(tonumber(soundVal))
				cdTracker_SaveSettings()
				cdTracker_LoadSettings()
				imcSound.PlaySoundEvent(soundTypes[settings.soundtype])
				return CHAT_SYSTEM('Sound type set to '..settings.soundtype..'.')
			end
			return CHAT_SYSTEM('Invalid sound value.')
		end
		if settings.sound == 1 then
			settings.sound = 0
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Sound off.')
		else
			settings.sound = 1
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Sound on.')
		end
	end
	if (cmd == 'icon') then
		if settings.icon == 1 then
			settings.icon = 0
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Icon off.')
		else
			settings.icon = 1
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Icon on.')
		end
	end
	if (cmd == 'text') then
		if settings.text == 1 then
			settings.text = 0
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Text off.')
		else
			settings.text = 1
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Text on.')
		end
	end
	if (cmd == 'list') then
		GET_SKILL_LIST()
		for k,v in ipairs(skillList) do
			local alertstatus = 'on'
			local chatstatus = 'off'
			if settings.ignoreList[v] ~= nil then
				if settings.ignoreList[v] == 1 then
					alertstatus = 'off'
				end
			end
			if settings.chatList[v] ~= nil then
				if settings.chatList[v] == 1 then
					chatstatus = 'on'
				end
			end
			CHAT_SYSTEM('ID '..k..': '..v..' - alert '..alertstatus..' - chat '..chatstatus)
		end
		return;
	end
	if (cmd == 'alert') then
		local skillID = table.remove(command,1)
		if skillList[tonumber(skillID)] ~= nil then
			if settings.ignoreList[skillList[tonumber(skillID)]] == 1 then
				settings.ignoreList[skillList[tonumber(skillID)]] = 0
				cdTracker_SaveSettings()
				cdTracker_LoadSettings()
				return CHAT_SYSTEM('Alerts on for '..skillList[tonumber(skillID)]..'.')
			end
			settings.ignoreList[skillList[tonumber(skillID)]] = 1
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Alerts off for '..skillList[tonumber(skillID)]..'.')
		end
		return CHAT_SYSTEM('Invalid skill ID.')
	end
	if (cmd == 'chat') then
		local skillID = table.remove(command,1)
		if skillList[tonumber(skillID)] ~= nil then
			if settings.chatList[skillList[tonumber(skillID)]] == 1 then
				settings.chatList[skillList[tonumber(skillID)]] = 0
				cdTracker_SaveSettings()
				cdTracker_LoadSettings()
				return CHAT_SYSTEM('Chat alerts off for '..skillList[tonumber(skillID)]..'.')
			end
			settings.chatList[skillList[tonumber(skillID)]] = 1
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Chat alerts on for '..skillList[tonumber(skillID)]..'.')
		end
		return CHAT_SYSTEM('Invalid skill ID.')
	end
	if cmd == 'status' then
		cdTracker_SaveSettings()
		cdTracker_LoadSettings()
		CHAT_SYSTEM(' ')
		if settings.alerts == 0 then
			CHAT_SYSTEM('CD Tracker: off')
		else
			CHAT_SYSTEM('CD Tracker: on')
		end
		if settings.icon == 0 then
			CHAT_SYSTEM('Icon: off')
		else
			CHAT_SYSTEM('Icon: on')
		end
		if settings.text == 0 then
			CHAT_SYSTEM('Text: off')
		else
			CHAT_SYSTEM('Text: on')
		end
		if settings.sound == 0 then
			CHAT_SYSTEM('Sound: off')
		else
			CHAT_SYSTEM('Sound: on')
		end
		CHAT_SYSTEM('Sound type: '..settings.soundtype)
		CHAT_SYSTEM(' ')
		return;
	end
	if (cmd == 'reset') then
		settings = default
		cdTracker_SaveSettings()
		cdTracker_LoadSettings()
		return CHAT_SYSTEM('All settings reset to defaults.')
	end
	if (cmd == 'shout') then
		local skillID = table.remove(command,1)
		if skillList[tonumber(skillID)] ~= nil then
			if settings.shout[skillList[tonumber(skillID)]] == 1 then
				settings.shout[skillList[tonumber(skillID)]] = 0
				cdTracker_SaveSettings()
				cdTracker_LoadSettings()
				return CHAT_SYSTEM('Shout off for '..skillList[tonumber(skillID)]..'.')
			end
			settings.shout[skillList[tonumber(skillID)]] = 1
			cdTracker_SaveSettings()
			cdTracker_LoadSettings()
			return CHAT_SYSTEM('Shout on for '..skillList[tonumber(skillID)]..'.')
		end
		return CHAT_SYSTEM('Invalid skill ID.')
	end
	CHAT_SYSTEM(' ')
	CHAT_SYSTEM('Available commands:')
	CHAT_SYSTEM('/cd on')
	CHAT_SYSTEM('/cd off')
	CHAT_SYSTEM('/cd <seconds>')
	CHAT_SYSTEM('/cd icon')
	CHAT_SYSTEM('/cd text')
	CHAT_SYSTEM('/cd sound')
	CHAT_SYSTEM('/cd sound <number>')
	CHAT_SYSTEM('/cd list')
	CHAT_SYSTEM('/cd alert <ID>')
	CHAT_SYSTEM('/cd chat <ID>')
	CHAT_SYSTEM('/cd status')
	CHAT_SYSTEM('/cd reset')
	CHAT_SYSTEM(' ')
	cdTracker_SaveSettings()
	cdTracker_LoadSettings()
	return;
end

function QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME_HOOKED(frame)
	queue = {}
	oldVal = {}
	skillCd = {}	
	_G['QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME_OLD'](frame)
end
	
function CDTRACKER_ON_INIT(addon, frame)
	acutil.setupHook(ICON_USE_HOOKED,'ICON_USE')
	acutil.setupHook(ICON_UPDATE_SKILL_COOLDOWN_HOOKED,'ICON_UPDATE_SKILL_COOLDOWN')
	acutil.setupHook(QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME_HOOKED,'QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME')
	acutil.slashCommand('/cd',cdTracker_SetVal)
	GET_SKILL_LIST()
	cdTracker_LoadSettings()
end
	
function ICON_USE_HOOKED(object, reAction)
	_G['ICON_USE_OLD'](object, reAction);
	local iconPt = object;
	if iconPt  ~=  nil then
		local icon = tolua.cast(iconPt, 'ui::CIcon');
		local iconInfo = icon:GetInfo();
		local skillInfo = session.GetSkill(iconInfo.type);
		if skillInfo ~= nil then
			curTime = skillInfo:GetCurrentCoolDownTime();
			local sklObj = GetIES(skillInfo:GetObject());
			skillName = GetClassByType("Skill", sklObj.ClassID).ClassName
			fullName = string.sub(string.match(skillName,'_.+'),2):gsub("%u", " %1"):sub(2)
		end
		local cdCheck = math.ceil(curTime/1000)
		if cdCheck ~= 0 then
			
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			
			ui.AddText('SystemMsgFrame',fullName..' in '..cdCheck..'.')
		end
		if settings.shout[fullName] == 1 and cdCheck == 0 then
			ui.Chat('!!'..string.upper(fullName)..'!!')
		end
		if settings.chatList[fullName] == 1 and cdCheck == 0 then
			if fullName == "Safety Zone" then
				ui.Chat('!!'..string.upper(fullName)..' HERE!!')
				ui.Chat('{img emoticon_0020 30 30}{/}')
				ReserveScript('SOCIAL_POSE(0,0,0,22)', 1.2)
			end
			msgDisplay = 1
			timer = imcTime.GetAppTime()
		end
	else
		return;
	end
end

function ICON_UPDATE_SKILL_COOLDOWN_HOOKED(icon)
	if settings.alerts == 0 then
		return _G['ICON_UPDATE_SKILL_COOLDOWN_OLD'](icon)
	end
	local iconInfo = icon:GetInfo();
	local skillInfo = session.GetSkill(iconInfo.type);
	if skillInfo ~= nil then
		
		curTime = skillInfo:GetCurrentCoolDownTime();
		totalTime = skillInfo:GetTotalCoolDownTime();
		local sklObj = GetIES(skillInfo:GetObject());
		obj = GetClassByType("Skill", sklObj.ClassID);
		skillName = GetClassByType("Skill", sklObj.ClassID).ClassName
		
		fullName = string.sub(string.match(skillName,'_.+'),2):gsub("%u", " %1"):sub(2)

		skillCd[fullName] = curTime
		if queue[fullName] == nil then
			queue[fullName] = -1
		end
	end
	cdCheck = math.ceil(skillCd[fullName]/1000)
	if settings.checkVal >= cdCheck and cdCheck~=oldVal[fullName] then
		if oldVal[fullName] == 1 and cdCheck == 0 then
			if settings.sound == 1 then
				if settings.soundtype > 0 and settings.soundtype <= table.getn(soundTypes) then
					imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
				else
					imcSound.PlaySoundEvent(soundTypes[1])
				end
			end	
			-- if settings.text == 1 and settings.ignoreList[fullName] ~= 1 then
				-- ui.AddText('SystemMsgFrame',' ')
				-- ui.AddText('SystemMsgFrame',' ')
				-- ui.AddText('SystemMsgFrame',' ')
				
				-- ui.AddText('SystemMsgFrame',fullName..' ready.')
			-- end
			-- if settings.chatList[fullName] == 1 then
				-- ui.Chat('!!'..fullName..' ready!')
				-- msgDisplay = 1
				-- timer = imcTime.GetAppTime()
			-- end
			--SOCIAL_POSE(0,0,0,22)
			oldVal[fullName] = 0
			DRAW_READY_ICON(obj,2.5,tonumber(FIND_NEXT_SLOT(iconSlots,fullName)),60,60)
			iconSlots[tostring(FIND_NEXT_SLOT(iconSlots,fullName))] = 0
			counter = counter - 1
			if counter == 0 then
				-- for k,v in pairs(queue) do
					-- ui.DestroyFrame('SKILL_FRAME_'..v)
				-- end
				offset = 0
			end
			queue[fullName] = -1
			return curTime, totalTime;
		end
		if settings.text == 1 and settings.ignoreList[fullName] ~= 1 then
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			
			ui.AddText('SystemMsgFrame',fullName..' ready in '..cdCheck..' seconds.')
		end
		if settings.chatList[fullName] == 1 then
			ui.Chat('!!'..fullName..' in '..cdCheck)
			msgDisplay = 1
			timer = imcTime.GetAppTime()
		end
		oldVal[fullName] = cdCheck
		if queue[fullName] == -1 and cdCheck > 0 and settings.ignoreList[fullName] ~= 1 then
			if FIND_NEXT_SLOT(iconSlots,0) == nil then
				iconSlots[tostring(counter)] = fullName
				queue[fullName] = counter
			else
				iconSlots[tostring(FIND_NEXT_SLOT(iconSlots,0))] = fullName
				queue[fullName] = tonumber(FIND_NEXT_SLOT(iconSlots,fullName))
			end
			counter = counter + 1
		end
		if skillCd[fullName] < 500 and settings.ignoreList[fullName] ~= 1 then
			local countUp = 500 - skillCd[fullName]
			local scaleUp = 50 + (countUp/500)*10
			DRAW_READY_ICON(obj,0.5,tonumber(FIND_NEXT_SLOT(iconSlots,fullName)),scaleUp,scaleUp)
		else
			DRAW_READY_ICON(obj,0.5,tonumber(FIND_NEXT_SLOT(iconSlots,fullName)),50,50)
		end
	end
	if settings.chatList[fullName] == 1 then
		if TIME_ELAPSED(2) and msgDisplay == 1 then
			ui.Chat('!!')
			msgDisplay = 0
		end
	end
	return curTime, totalTime;
end

function FIND_NEXT_SLOT(slotArr, searchVal)
	local minK = 9999
	for k,v in pairs(slotArr) do
		if v == searchVal then
			if tonumber(k) < tonumber(minK) then
				minK = k
			end
		end
	end
	if tonumber(minK) < 9999 then
		return minK
	else
		return nil;
	end
end

function DRAW_READY_ICON(obj,duration,iconPos,sizex,sizey)
	if settings.icon == 0 then
		return;
	end
	if iconPos/2 == math.floor(iconPos/2) then
		offset = 0 - 65 + 65*(iconPos/2)
	else
		offset = 0 - 65 - 65*(math.ceil(iconPos/2))
	end
	local iconname = "Icon_" .. obj.Icon
	skillFrame[iconPos] = ui.CreateNewFrame('cdtracker','SKILL_FRAME_'..iconPos)
	skillFrame[iconPos]:ShowWindow(1)
	skillFrame[iconPos]:SetDuration(duration)
	if sizex == 60 then
		skillFrame[iconPos]:SetOffset(screenWidth/2+offset-5, screenHeight/3.6-5);
	else
		skillFrame[iconPos]:SetOffset(screenWidth/2+offset, screenHeight/3.6);
	end
	iconFrame[iconPos] = GET_CHILD(skillFrame[iconPos], 'iconFrame', 'ui::CPicture')
	iconFrame[iconPos]:SetImage(iconname)
	iconFrame[iconPos]:Resize(sizex,sizey)
	iconFrame[iconPos]:SetGravity(ui.LEFT, ui.TOP);
end

function GET_SKILL_LIST()
	skillList = {}
	for k,v in pairs(queue) do
		table.insert(skillList, k)
	end
	table.sort(skillList)
end



function TIME_ELAPSED(val)
	local elapsed = math.floor(imcTime.GetAppTime() - timer)
	if elapsed > val then
		timer = imcTime.GetAppTime()
		return true
	end
	return false
end
