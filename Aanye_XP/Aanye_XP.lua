-- Local variables --

local db
local current_xp,max_xp
local rep_faction,start_rep,current_rep,_
local L = LibStub:GetLibrary( "AceLocale-3.0" ):GetLocale("Aanye_XP")

local rgbRested = "3399FF";
local rgbRep = { "FFFFFF","DD0000","FF4400","FFAA00","FFFF00","00FF00","11DD66","22BBAA","3399FF" }

-- Instantiate Frame/Object --

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Aanye_XP", {type = "data source", text = " ", icon = "Interface\\AddOns\\Aanye_XP\\level"})

-- Frame functions --

function f:PLAYER_LOGIN()
	db = LibStub:GetLibrary("AceDB-3.0"):New("Aanye_XP_DB", {
		global = {
			display_format = 0,
			},
		char = {
			track_exp = nil,
		},
	}, true)
	current_xp,max_xp = UnitXP("player"), UnitXPMax("player")
	if db.char.track_exp == nil then
		if MAX_PLAYER_LEVEL ~= UnitLevel("player") and not IsXPUserDisabled() then
			db.char.track_exp = 1
		else
			db.char.track_exp = 0
		end
	end

	self:SetFactionVars()

	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("UPDATE_FACTION")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
	
	self:PLAYER_XP_UPDATE()
	self:UPDATE_FACTION()
end

function f:SetFactionVars()
	rep_faction,_,_,_,current_rep = GetWatchedFactionInfo()
	rep_faction = rep_faction or "None"
	start_rep = current_rep
end

function f.formatRested(str)
	if GetXPExhaustion() then
		return '|cFF'.. rgbRested .. str .. '|r'
	else
		return str
	end
end

function f.formatStanding(str,standing)
	return '|cFF' .. rgbRep[standing+1] .. str .. '|r'
end

function f:SetBrokerText()
	local dotext
	if db.char.track_exp == 1 then
		dataobj.icon = "Interface\\AddOns\\Aanye_XP\\level"
		if MAX_PLAYER_LEVEL == UnitLevel("player") then
			dotext = L["Level"].." "..UnitLevel("player")
		elseif IsXPUserDisabled() then
			dotext = "XP Disabled"
		elseif db.global.display_format == 0 then
			dotext = current_xp.."/"..max_xp..f.formatRested(string.format(" (%d%%)", current_xp/max_xp*100))
		elseif db.global.display_format == 1 then
			dotext = (max_xp-current_xp)..f.formatRested(string.format(" (%d%%)", (max_xp-current_xp)/max_xp*100))
		elseif db.global.display_format == 2 then
			dotext = f.formatRested(string.format(" %01.1f%%", current_xp/max_xp*100))
		elseif db.global.display_format == 3 then
			dotext = f.formatRested(string.format(" %01.1f%%", (max_xp-current_xp)/max_xp*100))
		end
	else
		dataobj.icon = "Interface\\AddOns\\Aanye_XP\\rep"
		local name, standing, min, max, value = GetWatchedFactionInfo()
		if not name then
			dotext = L["No Faction Selected"]
		elseif db.global.display_format == 0 then
			dotext = (value-min).."/"..(max-min) .. f.formatStanding(string.format(" (%d%%)", start_rep > value and (max-value)/(max-min)*100 or (value-min)/(max-min)*100),standing)
		elseif db.global.display_format == 1 then
			dotext = (max-value) .. f.formatStanding(string.format(" (%d%%)", start_rep > value and (value-min)/(max-min)*100 or (max-value)/(max-min)*100),standing)
		elseif db.global.display_format == 2 then
			dotext = f.formatStanding(string.format(" %01.1f%%", start_rep > value and (max-value)/(max-min)*100 or (value-min)/(max-min)*100),standing)
		elseif db.global.display_format == 3 then
			dotext = f.formatStanding(string.format(" %01.1f%%", start_rep > value and (value-min)/(max-min)*100 or (max-value)/(max-min)*100),standing)
		end
	end
	dataobj.text = ' '..dotext..' '
end

-- Events --

function f:PLAYER_XP_UPDATE()
	current_xp = UnitXP("player")
	max_xp = UnitXPMax("player")
	self:SetBrokerText()
end

function f:UPDATE_FACTION()
	local faction = GetWatchedFactionInfo()
	if faction ~= rep_faction then self:SetFactionVars() end
	self:SetBrokerText()
end

-- Local Function --

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

-- OnClick --

function dataobj.OnClick(self,button)
	if button == "LeftButton" then
		db.char.track_exp = (db.char.track_exp+1)%2
	elseif button == "RightButton" then
		db.global.display_format = (db.global.display_format+1)%4
	end
	f.SetBrokerText()
	dataobj.SetTooltipContents()
end

function dataobj.SetTooltipContents()
	GameTooltip:ClearLines()

	if db.char.track_exp == 1 then
		GameTooltip:AddLine(L["Experience Summary"])
		GameTooltip:AddLine(" ")
		if MAX_PLAYER_LEVEL == UnitLevel("player") then
			GameTooltip:AddLine(L["Character is currently at maximum possible level."],1,1,1)
		elseif IsXPUserDisabled() then
			GameTooltip:AddLine(L["XP gains are disabled for this Character."],1,1,1)
		else
			GameTooltip:AddDoubleLine(L["Rest:"], string.format("%d%%", (GetXPExhaustion() or 0)/max_xp*100), nil,nil,nil, 1,1,1)
			GameTooltip:AddDoubleLine(L["Current Experience:"], current_xp.."/"..max_xp, nil,nil,nil, 1,1,1)
			GameTooltip:AddDoubleLine(L["Remaining to Level:"], max_xp-current_xp, nil,nil,nil, 1,1,1)
		end
	else
		local name, standing, min, max, value = GetWatchedFactionInfo()
		if not name then
			GameTooltip:AddLine(L["Reputation Summary:"],L["No Faction Selected"], nil,nil,nil, 1,1,1)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["To track a faction reputation, select a faction from the"],1,1,1)
			GameTooltip:AddLine(L["Reputation window and check \34Show as Experience Bar\34."],1,1,1)
		else
			GameTooltip:AddDoubleLine(L["Reputation Summary:"],name, nil,nil,nil, 1,1,1)
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(L["Standing:"],getglobal("FACTION_STANDING_LABEL"..standing), nil,nil,nil, 1,1,1)
			GameTooltip:AddDoubleLine(L["Current Reputation:"], (value-min).."/"..(max-min), nil,nil,nil, 1,1,1)
			if start_rep > value then
				if standing>1 then
					GameTooltip:AddDoubleLine(L["Remaining to X:"](getglobal("FACTION_STANDING_LABEL"..standing-1)),value-min,nil,nil,nil, 1,1,1)
				end
			else
				if standing<8 then
					GameTooltip:AddDoubleLine(L["Remaining to X:"](getglobal("FACTION_STANDING_LABEL"..standing+1)),max-value,nil,nil,nil, 1,1,1)
				end
			end
		end
	end

	--GameTooltip:AddLine(" ")
	--GameTooltip:AddDoubleLine(L["Aanye_XP"],L["By Aanye on Cenarius (US)"],0.6,0.6,0.6,0.6,0.6,0.6)

	GameTooltip:Show()
end

-- Tooltip --

function dataobj.OnLeave() GameTooltip:Hide() end
function dataobj.OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	dataobj.SetTooltipContents()
end

-- Startup Events --
if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
