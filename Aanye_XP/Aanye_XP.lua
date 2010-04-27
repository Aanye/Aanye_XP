-- Local variables --

local start_time,track_exp
local start_level,current_xp,max_xp,total_xp
local rep_faction,rep_standing,start_rep,current_rep,min_rep,max_rep,rep_trackchange
local L = LibStub:GetLibrary( "AceLocale-3.0" ):GetLocale("Aanye_XP")

-- Instantiate Frame/Object --

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Aanye_XP", {type = "data source", text = " ", icon = "Interface\\AddOns\\Aanye_XP\\level"})

-- Onload --

function f:PLAYER_LOGIN()
	current_xp,max_xp,start_time = UnitXP("player"), UnitXPMax("player"), GetTime()
	total_xp = -current_xp
	start_level = UnitLevel("player") + current_xp/max_xp

	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")

	self:SetFactionVars()
	rep_trackchange = false

	self:RegisterEvent("UPDATE_FACTION")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
	
	if MAX_PLAYER_LEVEL ~= UnitLevel("player") and not IsXPUserDisabled() then
		track_exp = 1
	else
		track_exp = 0
	end
	
	self:PLAYER_XP_UPDATE()
	self:UPDATE_FACTION()
end

function f:SetFactionVars()
	rep_faction,rep_standing,min_rep,max_rep,current_rep = GetWatchedFactionInfo()
	rep_faction = rep_faction or "None"
	start_rep = current_rep
	 
end

function f:SetBrokerText()
	if track_exp == 1 then
		dataobj.icon = "Interface\\AddOns\\Aanye_XP\\level"
		if MAX_PLAYER_LEVEL == UnitLevel("player") then
			dataobj.text = L["Level"].." "..UnitLevel("player")
		elseif IsXPUserDisabled() then
			dataobj.text = "XP Disabled"
		elseif GetXPExhaustion() then
			dataobj.text = current_xp .. '/' .. max_xp .. '|cFF3399FF' .. string.format(" (%d%%)", current_xp/max_xp*100) .. '|r'
		else
			dataobj.text = current_xp .. '/' .. max_xp .. string.format(" (%d%%)", current_xp/max_xp*100)
		end
	else
		dataobj.icon = "Interface\\AddOns\\Aanye_XP\\rep"
		local name, standing, min, max, value = GetWatchedFactionInfo()
		if not name then
			dataobj.text = L["No Faction Selected"]
		else
			dataobj.text = (value-min).."/"..(max-min)
		end
	end
end

-- Events --

function f:PLAYER_XP_UPDATE()
	current_xp = UnitXP("player")
	max_xp = UnitXPMax("player")
	self:SetBrokerText()
end

function f:PLAYER_LEVEL_UP()
	total_xp = total_xp + max_xp
end

function f:UPDATE_FACTION()
	local faction = GetWatchedFactionInfo()
	if faction ~= rep_faction then self:SetFactionVars() rep_trackchange = true end
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
		track_exp = 1-track_exp
	end
	f.SetBrokerText()
	dataobj.SetTooltipContents()
end

function dataobj.SetTooltipContents()
	GameTooltip:ClearLines()

	if track_exp == 1 then
		GameTooltip:AddLine(L["Experience Summary"])
		GameTooltip:AddLine(" ")
		if MAX_PLAYER_LEVEL == UnitLevel("player") then
			GameTooltip:AddLine(L["Character is currently at maximum possible level."],1,1,1)
		elseif IsXPUserDisabled() then
			GameTooltip:AddLine(L["XP gains are disabled for this Character."],1,1,1)
		else
			GameTooltip:AddDoubleLine(L["Current Experience:"], current_xp.."/"..max_xp, nil,nil,nil, 1,1,1)
			GameTooltip:AddDoubleLine(L["Rest:"], string.format("%d%%", (GetXPExhaustion() or 0)/max_xp*100), nil,nil,nil, 1,1,1)
			GameTooltip:AddDoubleLine(L["Remaining to Level:"], max_xp-current_xp, nil,nil,nil, 1,1,1)
			-- GameTooltip:AddLine((total_xp + current_xp).." experience gained this session", 1,1,1)
			-- GameTooltip:AddLine(string.format("%.2f levels gained this session", UnitLevel("player") + current_xp/max_xp - start_level), 1,1,1)
		end
	else
		local name, standing, min, max, value = GetWatchedFactionInfo()
		GameTooltip:AddDoubleLine(L["Reputation Summary"],name, nil,nil,nil, 1,1,1)
		GameTooltip:AddLine(" ")
		if not name then
			GameTooltip:AddLine(L["To track a faction reputation, select a faction from the"],1,1,1)
			GameTooltip:AddLine(L["Reputation window and check \34Show as Experience Bar\34."],1,1,1)
		else
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

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
