--CHANGE THESE SETTINGS FOR SIZE, GAP AND BORDER SIZE
-- /TCT ingame to move, toggle rings and hide
local PlayerFrameSize = 35;
local PartyFrameSize = 35;
local ArenaFrameSize = 35;
local PlayerIconGap = 3;
local PartyIconGap = 3;
local ArenaIconGap = 3;
local BorderSize = 2.8;  -- 0 or 1 or 2 or 3 or 4

TCT = LibStub("AceAddon-3.0"):NewAddon("TCT", "AceEvent-3.0", "AceConsole-3.0")
local TCTFrame = CreateFrame("Frame", "TCTFrame", UIParent, "BackdropTemplate")
TCTFrame.point = {"BOTTOM", UIParent, -207, 200} --Позиция иконок (сразу все 4 после /reload)
local TCTPlayerFrame = CreateFrame("Frame", "TCTPlayerFrame",TCTFrame, "BackdropTemplate")
    TCTPlayerFrame:SetPoint("CENTER", "UIParent",0,0)
    TCTPlayerFrame:SetSize(150,PlayerFrameSize)
    TCTPlayerFrame:SetBackdropColor(0,0,0,0.5)
    TCTPlayerFrame.elements = {}
    
local TCTParty1Frame = CreateFrame("Frame", "TCTParty1Frame",TCTFrame, "BackdropTemplate")
    TCTParty1Frame:SetPoint("CENTER", "UIParent",-200, 50);
    TCTParty1Frame:SetSize(150,PartyFrameSize)
    TCTParty1Frame:SetBackdropColor(0,0,0,.5)
    TCTParty1Frame.elements = {}
    
local TCTParty2Frame = CreateFrame("Frame", "TCTParty2Frame",TCTFrame, "BackdropTemplate")
    TCTParty2Frame:SetPoint("CENTER", "UIParent",-200,-50)
    TCTParty2Frame:SetSize(150,PartyFrameSize)
    TCTParty2Frame:SetBackdropColor(0,0,0,.5)
    TCTParty2Frame.elements = {}
    
local TCTArena1Frame = CreateFrame("Frame", "TCTArena1Frame",TCTFrame, "BackdropTemplate")
    TCTArena1Frame:SetPoint("CENTER", "UIParent", 460, 75)
    TCTArena1Frame:SetSize(150,ArenaFrameSize)
    TCTArena1Frame:SetBackdropColor(0,0,0,.5)
    TCTArena1Frame.elements = {}

local TCTArena2Frame = CreateFrame("Frame", "TCTArena2Frame",TCTFrame, "BackdropTemplate")
    TCTArena2Frame:SetPoint("CENTER", "UIParent", 460, 25)
    TCTArena2Frame:SetSize(150,ArenaFrameSize)
    TCTArena2Frame:SetBackdropColor(0,0,0,.5)
    TCTArena2Frame.elements = {}
    
local TCTArena3Frame = CreateFrame("Frame", "TCTArena3Frame",TCTFrame, "BackdropTemplate")
    TCTArena3Frame:SetPoint("CENTER", "UIParent", 460, -25)
    TCTArena3Frame:SetSize(150,ArenaFrameSize)
    TCTArena3Frame:SetBackdropColor(0,0,0,.5)
    TCTArena3Frame.elements = {}


local defaults = {
    profile = {
        TCTPlayerFrame= false,
        TCTParty1Frame = false,
        TCTParty2Frame = false,
        TCTArena1Frame = true,
        TCTArena2Frame = true,
        TCTArena3Frame = true,
        TCTPlayerFrameRings= true,
        TCTParty1FrameRings = true,
        TCTParty2FrameRings = true,
    }
 }
local GetInventoryItemLink = _G.GetInventoryItemLink
local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GetMacroInfo = _G.GetMacroInfo
local GetActionInfo = _G.GetActionInfo
local substr = _G.string.sub
local wipe = _G.wipe
local playerGUID = UnitGUID("player")
local party1GUID = UnitGUID("party1")
local party2GUID = UnitGUID("party2")
local arenaGUID = {}
local GetTime = _G.GetTime
local inArena

TCTFrame.spellToItem = TCTFrame.spellToItem or {}
TCTFrame.cooldownStartTimes = TCTFrame.cooldownStartTimes or {}
TCTFrame.cooldownDurations = TCTFrame.cooldownDurations or {}
TCTFrame.cooldowns = TCTFrame.cooldowns or nil


--apply drag functionality to any frame
  local applyDragFunctionality = function(self)
    --save the default position
    local getPoint = function(self)
      local pos = {}
      pos.a1, pos.af, pos.a2, pos.x, pos.y = self:GetPoint()
      if pos.af and pos.af:GetName() then pos.af = pos.af:GetName() end
      return pos
    end
    self.defaultPosition = getPoint(self)
    --the drag frame
    local df = CreateFrame("Frame",nil,self)
    df:SetAllPoints(self)
    df:SetFrameStrata("HIGH")
    df:SetHitRectInsets(0,0,0,0)
    df:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:GetParent():StartMoving() GameTooltip:Hide() end end)
    df:SetScript("OnDragStop", function(self) self:GetParent():StopMovingOrSizing() end)
    --dragframe texture
    local t = df:CreateTexture(nil,"OVERLAY",nil,6)
    t:SetAllPoints(df)
    t:SetTexture(0,1,0)
    t:SetAlpha(0.2)
    --dragframe text
    local txt = df:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("TOP",0,15,df)
    txt:SetJustifyH("CENTER")
    txt:SetJustifyV("CENTER")
    local txtt = df:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    txtt:SetPoint("BOTTOM",0,-15,df)
    txtt:SetJustifyH("CENTER")
    txtt:SetJustifyV("CENTER")
    --stuff
    df.txt = txt
    df.txtt = txtt
    df.texture = t
    df:Hide()
    self.dragframe = df
    self:SetClampedToScreen(true)
    self:SetMovable(true)
    self:SetUserPlaced(true)
    --helper functions
    --unlock
    local unlock = function(self)
      self:SetAlpha(1)
      if not self:IsUserPlaced() then return end
      if db[self:GetName()] then self.dragframe.txt:SetText(self:GetName()) else self.dragframe.txt:SetText("Hidden") self.dragframe.txt:SetTextColor(0.8,0,0) end
      if self:GetName() == "TCTPlayerFrame" or self:GetName() == "TCTParty1Frame" or self:GetName() == "TCTParty2Frame" then if db[self:GetName().."Rings"] then self.dragframe.txtt:SetText("Track Rings: Yes") else self.dragframe.txtt:SetText("Track Rings: No") end end
      self.dragframe:Show()
      self.dragframe:EnableMouse(true)
      self.dragframe:RegisterForDrag("LeftButton")
      self.dragframe:SetScript("OnEnter", function(self)
        if self:GetParent():GetName() == "TCTPlayerFrame" or self:GetParent():GetName() == "TCTParty1Frame" or self:GetParent():GetName() == "TCTParty2Frame" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self:GetParent():GetName(), 0, 1, 0.5, 1, 1, 1)
            GameTooltip:AddLine("* Click |cffffff00RIGHTBUTTON|r to Hide!", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddLine("* Hold down |cffffff00SHIFT|r+|cffffff00LEFTBUTTON|r to drag!", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddLine("* Hold |cffffff00CTRL|r+|cffffff00RIGHTCLICK|r to toggle rings!", 1, 1, 1, 1, 1, 1)

            GameTooltip:Show()
        else
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self:GetParent():GetName(), 0, 1, 0.5, 1, 1, 1)
            GameTooltip:AddLine("* Click |cffffff00RIGHTBUTTON|r to Hide!", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddLine("* Hold down |cffffff00SHIFT|r+|cffffff00LEFTBUTTON|r to drag!", 1, 1, 1, 1, 1, 1)
            GameTooltip:Show()
        end
      end)
      self.dragframe:SetScript("OnLeave", function() GameTooltip:Hide() end)
      self.dragframe:SetScript("OnMouseDown", function(self, button)
         if button == "RightButton" and not IsControlKeyDown() then
            if db[self:GetParent():GetName()] then
            self.txt:SetText("Hidden")
            self.txt:SetTextColor(0.8,0,0)
            db[self:GetParent():GetName()] = false
            else
            self.txt:SetText(self:GetParent():GetName())
            self.txt:SetTextColor(1,0.82,0)
            db[self:GetParent():GetName()] = true
            end
            GameTooltip:Hide()
         elseif button == "RightButton" and IsControlKeyDown() then
            if not db[self:GetParent():GetName().."Rings"] then
                db[self:GetParent():GetName().."Rings"] = true
                self.txtt:SetText("Track Rings: Yes")
            else
                db[self:GetParent():GetName().."Rings"] = false
                self.txtt:SetText("Track Rings: No")
            end
            GameTooltip:Hide()
         end
      end)
    end
    --lock
    local lock = function(self)
      if not self:IsUserPlaced() then return end
      self.dragframe:Hide()
    TCTFrame:UpdateIcon("player")
    TCTFrame:UpdateIcon("party1")
    TCTFrame:UpdateIcon("party2")
      --if not db["TCTPlayerFrame"] then TCTPlayerFrame:SetAlpha(0) else TCTPlayerFrame:SetAlpha(1) end
      self.dragframe:EnableMouse(false)
      self.dragframe:RegisterForDrag(nil)
      self.dragframe:SetScript("OnEnter", nil)
      self.dragframe:SetScript("OnLeave", nil)
    end
    --reset position
    local reset = function(self)
      if self.defaultPosition then
        self:ClearAllPoints()
        local pos = self.defaultPosition
        if pos.af and pos.a2 then
            self:SetPoint(pos.a1 or "CENTER", pos.af, pos.a2, pos.x or 0, pos.y or 0)
        elseif pos.af then
            self:SetPoint(pos.a1 or "CENTER", pos.af, pos.x or 0, pos.y or 0)
        else
            self:SetPoint(pos.a1 or "CENTER", pos.x or 0, pos.y or 0)
        end
      else
        self:SetPoint("CENTER",0,0)
      end
    end
    self.unlock = unlock
    self.lock = lock
    self.reset = reset
  end
  
  
    applyDragFunctionality(TCTPlayerFrame)
    applyDragFunctionality(TCTParty1Frame)
    applyDragFunctionality(TCTParty2Frame)
    applyDragFunctionality(TCTArena1Frame)
    applyDragFunctionality(TCTArena2Frame)
    applyDragFunctionality(TCTArena3Frame)
    
    
    local function SlashCmd(cmd)
    if (cmd:match"unlock") then
      TCTPlayerFrame.unlock(TCTPlayerFrame)
      TCTPlayerFrame.unlock(TCTParty1Frame)
      TCTPlayerFrame.unlock(TCTParty2Frame)
      TCTPlayerFrame.unlock(TCTArena1Frame)
      TCTPlayerFrame.unlock(TCTArena2Frame)
      TCTPlayerFrame.unlock(TCTArena3Frame)
    elseif (cmd:match"lock") then
      TCTPlayerFrame.lock(TCTPlayerFrame)
      TCTPlayerFrame.lock(TCTParty1Frame)
      TCTPlayerFrame.lock(TCTParty2Frame)
      TCTPlayerFrame.lock(TCTArena1Frame)
      TCTPlayerFrame.lock(TCTArena2Frame)
      TCTPlayerFrame.lock(TCTArena3Frame)
    elseif (cmd:match"reset") then
      TCTPlayerFrame.reset(TCTPlayerFrame)
      TCTPlayerFrame.reset(TCTParty1Frame)
      TCTPlayerFrame.reset(TCTParty2Frame)
      TCTPlayerFrame.reset(TCTArena1Frame)
      TCTPlayerFrame.reset(TCTArena2Frame)
      TCTPlayerFrame.reset(TCTArena3Frame)
    else
    print("TCT Commands:")
    print("/tct unlock")
    print("/tct lock")
    print("/tct reset")
    end
  end
 
  SlashCmdList["tct"] = SlashCmd;
  SLASH_tct1 = "/tct";
  
if not TCTFrame.eventFrame then
    TCTFrame.eventFrame = CreateFrame("Frame")
    TCTFrame.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    TCTFrame.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    TCTFrame.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    TCTFrame.eventFrame:RegisterEvent("PLAYER_LOGIN")
    TCTFrame.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    TCTFrame.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    TCTFrame.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        frame.TCTFrame[event](frame.TCTFrame, event, ...)
    end)
end
TCTFrame.eventFrame.TCTFrame = TCTFrame

local INVALID_EVENTS = {
    SPELL_DISPEL            = true,
    SPELL_DISPEL_FAILED     = true,
    SPELL_STOLEN            = true,
    SPELL_AURA_REMOVED      = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_BROKEN       = true,
    SPELL_AURA_BROKEN_SPELL = true,
    SPELL_CAST_FAILED       = true
}

local slots = {
    AMMOSLOT = 0,
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_FINGER = {11, 12},
    INVTYPE_TRINKET = {13, 14},
    INVTYPE_CLOAK = 15,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_WEAPON = {16, 17},
    INVTYPE_HOLDABLE = 17,
    INVTYPE_SHIELD = 17,
    INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_RANGED = 18
}

function TCTFrame:PLAYER_ENTERING_WORLD()
    playerGUID = UnitGUID("player")
    self:UpdateIcon("player")
    self:UpdateIcon("party1")
    self:UpdateIcon("party2")
    
end
function TCT:OnInitialize()
TCTFrame.db = LibStub("AceDB-3.0"):New("TCTDB", defaults)
db = TCTFrame.db.profile
end
local function isEquipped(itemID, unit)
    if unit == player or unit == party1 or unit == party2 then
        local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
        local slot = slots[equipLoc]
        if type(slot) == "table" then
            for _, v in ipairs(slot) do
                NotifyInspect(unit)
                local link = GetInventoryItemLink(unit, v)
                if link and link:match(("item:%s"):format(itemID)) then
                    return true
                end
            end
        else
            NotifyInspect(unit)
            local link = GetInventoryItemLink(unit, slot)
            if link and link:match(("item:%s"):format(itemID)) then
                return true
            end
        end
        return false
    else
        return true
    end
end

function TCTFrame:COMBAT_LOG_EVENT_UNFILTERED(generalEvent)
	local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags_, spellID, spellName, spellSchool, auraType = CombatLogGetCurrentEventInfo()

    playerGUID = playerGUID or UnitGUID("player")
    party1GUID = party1GUID or UnitGUID("party1")
    party2GUID = party2GUID or UnitGUID("party2")
    if inArena then
        for i=1,3 do
            if (UnitExists("arena"..i)) then arenaGUID[i] = arenaGUID[i] or UnitGUID("arena"..i) end
        end
    end

    if (playerGUID == sourceGUID or party1GUID == sourceGUID or party2GUID == sourceGUID or arenaGUID[1] == sourceGUID or arenaGUID[2] == sourceGUID or arenaGUID[3] == sourceGUID) and not INVALID_EVENTS[event] and substr(event, 0, 6) == "SPELL_" then
        local unit
        if sourceGUID == playerGUID then unit = "player"
        elseif sourceGUID == party1GUID then unit = "party1"
        elseif sourceGUID == party2GUID then unit = "party2"
        elseif sourceGUID == arenaGUID[1] then unit = "arena1" 
        elseif sourceGUID == arenaGUID[2] then unit = "arena2" 
        elseif sourceGUID == arenaGUID[3] then unit = "arena3"  
        end
		--print(spellID)
        local itemID = TCTFrame.spellToItem[spellID]
        if itemID then
		--print(itemID)
            if type(itemID) == "table" then
            local stop = false
                for k, v in ipairs(itemID) do
                    if isEquipped(v,unit) then
                        if unit == "player" or unit == "party1" or unit == "party2" then
                            self:SetCooldownFor(v, spellID, unit)
                        elseif stop == false then
                            self:SetCooldownFor(v, spellID, unit)
                            stop = true
                        end
                    end
                end
                return
            else
                if isEquipped(itemID,unit) then
                    self:SetCooldownFor(itemID, spellID,  unit)
                end
                return
            end
        end
    end
end

function TCTFrame:SetCooldownFor(itemID, spellID, unit)
    local duration = TCTFrame.cooldowns[spellID] or 0
    TCTFrame.cooldownStartTimes[itemID] = GetTime()
    TCTFrame.cooldownDurations[itemID] = duration
    local GetTime = GetTime()
    --print("Setting Cooldown for:"..spellID.." Unit: "..unit)
    TCTFrame:Proc(itemID, spellID, GetTime, duration, unit)

end
function TCTFrame:ShoworHideFrames()
    if db["TCTPlayerFrame"] then TCTPlayerFrame:SetAlpha(1) else TCTPlayerFrame:SetAlpha(0) end
    if db["TCTParty1Frame"] then TCTParty1Frame:SetAlpha(1) else TCTParty1Frame:SetAlpha(0) end
    if db["TCTParty2Frame"] then TCTParty2Frame:SetAlpha(1) else TCTParty2Frame:SetAlpha(0) end
    if db["TCTArena1Frame"] then TCTArena1Frame:SetAlpha(1) else TCTArena1Frame:SetAlpha(0) end
    if db["TCTArena2Frame"] then TCTArena2Frame:SetAlpha(1) else TCTArena2Frame:SetAlpha(0) end
    if db["TCTArena3Frame"] then TCTArena3Frame:SetAlpha(1) else TCTArena3Frame:SetAlpha(0) end
end

local spellToItem = {
    [36347] = 30293,
    [33667] = 28041,
    [64411] = 46017,
    [60065] = {44914, 40684, 49074},
    [60488] = 40373,
    [64713] = 45518,
    [60064] = {44912, 40682, 49706},
    [67703] = {47303, 47115},
    [67708] = {47115, 47303},
    [42292] = {51377, 51378},
    [67772] = {47131, 47464},
    [67773] = {47464, 47131},
    [72416] = {50398, 50397},
    [72412] = {50402, 50401, 52572, 52571},
    [72418] = {50399, 50400},
    [72414] = {50404, 50403},
    [71485] = 50362,
    [71492] = 50362,
    [71486] = 50362,
    [71484] = 50362,
    [71491] = 50362,
    [71487] = 50362,
    [71556] = 50363,
    [71560] = 50363,
    [71558] = 50363,
    [71561] = 50363,
    [71559] = 50363,
    [71557] = 50363,    
    [71403] = 50198,
    [71610] = 50359,
    [71633] = 50352,
    [71601] = 50353,
    [71584] = 50358,
    [71401] = 50342,
    [71605] = 50360,
    [71541] = 50343,
    [71641] = 50366,
    [71639] = 50349,
    [71644] = 50348,
    [71636] = 50365,
    [75458] = 54569,
    [75466] = 54572,
    [71607] = {50726, 50354},
    [71572] = 50340,
    [71579] = 50357,
    [71574] = 50346,
    [71638] = 50364,
    [71635] = 50361,
    [71586] = 50356,
    [71396] = 50355,
    [71432] = 50351,
    -- [75490]  = 54573,
    [75477] = 54571,
    [75456] = 54590,
    [75473] = 54588,            
    -- [75495]  = 54589,
    [75480] = 54591,
    [67117] = {48501, 48502, 48503, 48504, 48505, 48472, 48474, 48476, 48478, 48480, 48491, 48492, 48493, 48494, 48495, 48496, 48497, 48498, 48499, 48500, 48486, 48487, 48488, 48489, 48490, 48481, 48482, 48483, 48484, 48485},
    [67671] = 47214,
    [67669] = 47213,
    [64772] = 45609,
    [65024] = 46038,
    [60443] = 40371,
    [64790] = 45522,
    [60203] = 42990,
    [60494] = 40255,
    [65004] = 65005,
    [60492] = 39229,
    [60530] = 40258,
    [60437] = 40256,
    [49623] = 37835,
    [65019] = 45931,
    [64741] = 45490,
    [65014] = 45286,
    [65003] = 45929,
    [60538] = 40382,
    [58904] = 43573,
    [60062] = {40685, 49078},
    [64765] = 45507,
    [51353] = 38358,
    [60218] = 37220,
    [60479] = 37660,
    [51348] = 38359,
    [63250] = 45131,
    [63250] = 45219,
    [60302] = 37390,
    [54808] = 40865,
    [60483] = 37264,
    [52424] = 38675,
    [55018] = 40767,
    [52419] = 38674,
    -- [18350] = 37111,
    [60520] = 37657,
    [60307] = 37064,
    [60233] = {44253, 44254, 44255, 42987},
    [60235] = {44253, 44254, 44255, 42987},
    [60229] = {44253, 44254, 44255, 42987},
    [60234] = {44253, 44254, 44255, 42987},
    [23684] = 19288,
    [67750] = {47059, 47432},
    [67696] = {47041, 47271},
    [60443] = 40371,
    [71572] = 50345,
}

local cooldowns = {
    [36347] = 90,
    [33667] = 90,
    [72416] = 60,
    [72412] = 60,
    [72418] = 60,
    [72414] = 60,
    [60488] = 15,
    [51348] = 10,
    [51353] = 10,
    [54808] = 60,
    [55018] = 60,
    [52419] = 30,
    [59620] = 90,
    [55382] = 15,
    [32848] = 15,
    [55341] = 90,
    [48517] = 30,
    [48518] = 30,
    [47755] = 12,
    [71485] = 105,
    [71492] = 105,
    [71486] = 105,
    [71484] = 105,
    [71491] = 105,
    [71487] = 105,
    [71556] = 105,
    [71560] = 105,
    [71558] = 105,
    [71561] = 105,
    [71559] = 105,
    [71557] = 105,
    [71605] = 100,
    [71636] = 100,
    [75458] = 45,
    [75466] = 45,
    [71607] = 120,
    [71607] = 120,
    [67708] = 45,
    [67703] = 45,
    [67772] = 45,
    [67773] = 45,
    [71601] = 75,
    [71584] = 45,
    [60065] = 45,
    [64713] = 45,
    [75495] = 120,
    [75490] = 120,
    [71579] = 120,
    [71644] = 45,
    [60064] = 45,
    [71574] = 120,
    [71638] = 60,
    [71635] = 60,
    [71586] = 120,
    -- [75490]  = 54573,
    [75477] = 45,
    [75456] = 45,
    [75473] = 45,           
    -- [75495]  = 54589,
    [75480] = 45,
    [59626] = 35,
    [59625] = 35,   
    [42292] = 120,
    [71401] = 45,
    [71541] = 45,
    [60443] = 45,
    [71572] = 0,
    
    
}
local rings = {
    50397,
    52572,
    52571,
    50398,
    50399,
    50400,
    50401,
    50402,
    50403,
    50404,
}
local function contains(list, x)
    for _, v in pairs(list) do
        if v == x then return true end
    end
    return false
end

TCTFrame.spellToItem = TCTFrame.spellToItem or {}
TCTFrame.cooldowns = TCTFrame.cooldowns or {}

local tt, tts = {}, {}
local function merge(t1, t2)
    wipe(tts)
    for _, v in ipairs(t1) do
        tts[v] = true
    end
    for _, v in ipairs(t2) do
        if not tts[v] then
            tinsert(t1, v)
        end
    end
end

for k, v in pairs(spellToItem) do
    local e = TCTFrame.spellToItem[k]
    if e and e ~= v then
        if type(e) == "table" then
            if type(v) ~= "table" then
                wipe(tt)
                tinsert(tt, v)
            end
            merge(e, tt)
        else
            TCTFrame.spellToItem[k] = {e, v}
        end
    else
        TCTFrame.spellToItem[k] = v
    end
end

for k, v in pairs(cooldowns) do
    TCTFrame.cooldowns[k] = v
end

TCTFrame.bd = {bgFile =  "Interface\\Buttons\\WHITE8X8",
        edgeFile =  "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = -1, edgeSize = BorderSize,
        insets = { left = -1, right = -1, top = -1, bottom = -1
        }}

function TCTFrame:CreateElements()
    --Player Frame
    for i=11, 14 do
      local TCTPlayerIconFrame = CreateFrame("frame", "TCTPlayerIconFrame "..i,TCTPlayerFrame, "BackdropTemplate")
        TCTPlayerIconFrame.cd2 = CreateFrame("cooldown", "PlayerCDFrame "..i, TCTPlayerIconFrame, "BackdropTemplate")
        TCTPlayerIconFrame.tex = TCTPlayerIconFrame:CreateTexture(nil, "OVERLAY")
        TCTPlayerFrame.elements[i] = TCTPlayerIconFrame
        TCTPlayerFrame.elements[i].slot = i
        TCTPlayerIconFrame:SetBackdrop(TCTFrame.bd)
        
        TCTPlayerIconFrame.tex:SetTexCoord(.07, .93, .07, .93)
        TCTPlayerIconFrame.tex:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTPlayerIconFrame.tex:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        
        TCTPlayerIconFrame.cd2:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTPlayerIconFrame.cd2:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        

        TCTPlayerIconFrame:SetSize(TCTPlayerFrame:GetHeight(), TCTPlayerFrame:GetHeight())
        TCTPlayerIconFrame:SetBackdropColor(0,0,0,0.6)
        TCTPlayerIconFrame:SetBackdropBorderColor(.1,.6,.1)
        TCTPlayerIconFrame:SetAlpha(0)
        if i==11 or i==12 then
            TCTPlayerIconFrame:SetPoint("LEFT")
        else
            TCTPlayerIconFrame:SetPoint("LEFT", TCTPlayerFrame.elements[i-1], "RIGHT", PlayerIconGap, 0)
        end
    end
    --Party1
    for i=11, 14 do
      local TCTParty1IconFrame = CreateFrame("frame", "TCTParty1IconFrame "..i,TCTParty1Frame, "BackdropTemplate")
        TCTParty1IconFrame.cd2 = CreateFrame("cooldown", "TCTParty1CDFrame "..i, TCTParty1IconFrame, "BackdropTemplate")
        TCTParty1IconFrame.tex = TCTParty1IconFrame:CreateTexture(nil, "OVERLAY")
        TCTParty1Frame.elements[i] = TCTParty1IconFrame
        TCTParty1Frame.elements[i].slot = i
        TCTParty1IconFrame.cd2:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTParty1IconFrame.cd2:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTParty1IconFrame.tex:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTParty1IconFrame.tex:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTParty1IconFrame.tex:SetTexCoord(.07, .93, .07, .93)
        TCTParty1IconFrame:SetSize(TCTParty1Frame:GetHeight(), TCTParty1Frame:GetHeight())
        TCTParty1IconFrame:SetBackdrop(TCTFrame.bd)
        TCTParty1IconFrame:SetBackdropColor(0,0,0,.6)
        TCTParty1IconFrame:SetBackdropBorderColor(.1,.6,.1)
        TCTParty1IconFrame:SetAlpha(0)
        if i==11 or i==12 then
            TCTParty1IconFrame:SetPoint("LEFT")
        else
            TCTParty1IconFrame:SetPoint("LEFT", TCTParty1Frame.elements[i-1], "RIGHT", PartyIconGap, 0)
        end
    end
    --Party2
    for i=11, 14 do
      local TCTParty2IconFrame = CreateFrame("frame", "TCTParty2IconFrame "..i,TCTParty2Frame, "BackdropTemplate")
        TCTParty2IconFrame.cd2 = CreateFrame("cooldown", "TCTParty2CDFrame "..i, TCTParty2IconFrame, "BackdropTemplate")
        TCTParty2IconFrame.tex = TCTParty2IconFrame:CreateTexture(nil, "OVERLAY")
        TCTParty2Frame.elements[i] = TCTParty2IconFrame
        TCTParty2Frame.elements[i].slot = i
        TCTParty2IconFrame.cd2:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTParty2IconFrame.cd2:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTParty2IconFrame.tex:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTParty2IconFrame.tex:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTParty2IconFrame.tex:SetTexCoord(.07, .93, .07, .93)
        TCTParty2IconFrame:SetSize(TCTParty2Frame:GetHeight(), TCTParty2Frame:GetHeight())
        TCTParty2IconFrame:SetBackdrop(TCTFrame.bd)
        TCTParty2IconFrame:SetBackdropColor(0,0,0,.6)
        TCTParty2IconFrame:SetBackdropBorderColor(.1,.6,.1)
        TCTParty2IconFrame:SetAlpha(0)
        if i==11 or i==12 then
            TCTParty2IconFrame:SetPoint("LEFT")
        else
            TCTParty2IconFrame:SetPoint("LEFT", TCTParty2Frame.elements[i-1], "RIGHT", PartyIconGap, 0)
        end
    end
    --Arena1
    for i=11, 14 do
      local TCTArena1IconFrame = CreateFrame("frame", "TCTArena1IconFrame "..i,TCTArena1Frame, "BackdropTemplate")
        TCTArena1IconFrame.cd2 = CreateFrame("cooldown", "TCTArena1CDFrame "..i, TCTArena1IconFrame, "BackdropTemplate")
        TCTArena1IconFrame.tex = TCTArena1IconFrame:CreateTexture(nil, "OVERLAY")
        TCTArena1Frame.elements[i] = TCTArena1IconFrame
        TCTArena1Frame.elements[i].slot = i
        TCTArena1IconFrame.cd2:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTArena1IconFrame.cd2:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTArena1IconFrame.tex:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTArena1IconFrame.tex:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTArena1IconFrame.tex:SetTexCoord(.07, .93, .07, .93)
        TCTArena1IconFrame:SetSize(TCTArena1Frame:GetHeight(), TCTArena1Frame:GetHeight())
        TCTArena1IconFrame:SetBackdrop(TCTFrame.bd)
        TCTArena1IconFrame:SetBackdropColor(0,0,0,.6)
        TCTArena1IconFrame:SetBackdropBorderColor(.1,.6,.1)
        TCTArena1IconFrame:SetAlpha(0)
        if i==11 or i==12 then
            TCTArena1IconFrame:SetPoint("LEFT")
        else
            TCTArena1IconFrame:SetPoint("LEFT", TCTArena1Frame.elements[i-1], "RIGHT",  ArenaIconGap, 0)
        end
    end
    --Arena2
    for i=11, 14 do
      local TCTArena2IconFrame = CreateFrame("frame", "TCTArena2IconFrame "..i,TCTArena2Frame, "BackdropTemplate")
        TCTArena2IconFrame.cd2 = CreateFrame("cooldown", "TCTArena2CDFrame "..i, TCTArena2IconFrame, "BackdropTemplate")
        TCTArena2IconFrame.tex = TCTArena2IconFrame:CreateTexture(nil, "OVERLAY")
        TCTArena2Frame.elements[i] = TCTArena2IconFrame
        TCTArena2Frame.elements[i].slot = i
        TCTArena2IconFrame.cd2:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTArena2IconFrame.cd2:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTArena2IconFrame.tex:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTArena2IconFrame.tex:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTArena2IconFrame.tex:SetTexCoord(.07, .93, .07, .93)
        TCTArena2IconFrame:SetSize(TCTArena2Frame:GetHeight(), TCTArena2Frame:GetHeight())
        TCTArena2IconFrame:SetBackdrop(TCTFrame.bd)
        TCTArena2IconFrame:SetBackdropColor(0,0,0,.6)
        TCTArena2IconFrame:SetBackdropBorderColor(.1,.6,.1)
        TCTArena2IconFrame:SetAlpha(0)
        if i==11 or i==12 then
            TCTArena2IconFrame:SetPoint("LEFT")
        else
            TCTArena2IconFrame:SetPoint("LEFT", TCTArena2Frame.elements[i-1], "RIGHT", ArenaIconGap, 0)
        end
    end
    --Arena3
    for i=11, 14 do
      local TCTArena3IconFrame = CreateFrame("frame", "TCTArena3IconFrame "..i,TCTArena3Frame, "BackdropTemplate")
        TCTArena3IconFrame.cd2 = CreateFrame("cooldown", "TCTArena3CDFrame "..i, TCTArena3IconFrame, "BackdropTemplate")
        TCTArena3IconFrame.tex = TCTArena3IconFrame:CreateTexture(nil, "OVERLAY")
        TCTArena3Frame.elements[i] = TCTArena3IconFrame
        TCTArena3Frame.elements[i].slot = i
        TCTArena3IconFrame.cd2:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTArena3IconFrame.cd2:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTArena3IconFrame.tex:SetPoint("TOPLEFT", BorderSize,-BorderSize)
        TCTArena3IconFrame.tex:SetPoint("BOTTOMRIGHT", -BorderSize, BorderSize)
        TCTArena3IconFrame.tex:SetTexCoord(.07, .93, .07, .93)
        TCTArena3IconFrame:SetSize(TCTArena3Frame:GetHeight(), TCTArena3Frame:GetHeight())
        TCTArena3IconFrame:SetBackdrop(TCTFrame.bd)
        TCTArena3IconFrame:SetBackdropColor(0,0,0,.6)
        TCTArena3IconFrame:SetBackdropBorderColor(.1,.6,.1)
        TCTArena3IconFrame:SetAlpha(0)
        if i==11 or i==12 then
            TCTArena3IconFrame:SetPoint("LEFT")
        else
            TCTArena3IconFrame:SetPoint("LEFT", TCTArena3Frame.elements[i-1], "RIGHT", ArenaIconGap, 0)
        end
    end
    
    TCTFrame:ShoworHideFrames()
end
function TCTFrame:CreateHolder()
    self:SetParent(UIParent, "BackdropTemplate")
    --self:SetSize(100,35)
    self:SetPoint(unpack(TCTFrame.point))
    self:SetBackdropColor(0,0,0,.5)
    self:CreateElements()
end
function TCTFrame:UpdateIcon(unit)
    if unit == "player" then 
        for i=11,14 do
            TCTPlayerFrame.elements[i].tex:SetTexture(nil)
            local itemID = GetInventoryItemID(unit, i)
            if itemID then
            TCTPlayerFrame.elements[i].id = itemID
            local icon = GetItemIcon(itemID)
                if not TCTPlayerFrame.elements[i].tex:GetTexture() and (contains(rings,itemID) and db["TCTPlayerFrameRings"]) then
                    TCTPlayerFrame.elements[i].tex:SetTexture(icon)
                    TCTPlayerFrame.elements[i]:SetAlpha(1)
                elseif not TCTPlayerFrame.elements[i].tex:GetTexture() and i>12 then
                    TCTPlayerFrame.elements[i].tex:SetTexture(icon)
                    TCTPlayerFrame.elements[i]:SetAlpha(1)
                    local startTime, duration, enable = GetItemCooldown(itemID)
                    if duration ~= 0 then
                        TCTPlayerFrame.elements[i].cd2:SetAlpha(1)
                        TCTPlayerFrame.elements[i].cd2:SetScript("OnHide", function(fr) fr:GetParent():SetBackdropBorderColor(.1,.6,.1) end)
                        TCTPlayerFrame.elements[i].cd2:SetCooldown(startTime,duration)
                        TCTPlayerFrame.elements[i]:SetBackdropBorderColor(.8,.2,.2)                     
                    else
                        TCTPlayerFrame.elements[i].cd2:SetCooldown(0,0)
                        TCTPlayerFrame.elements[i].cd2:SetAlpha(0)
                    end
                    TCTPlayerFrame.elements[i]:SetAlpha(1)
                elseif not TCTPlayerFrame.elements[i].tex:GetTexture() then
                TCTPlayerFrame.elements[i]:SetAlpha(0)
                end
            end
            TCTPlayerFrame.elements[i].timer = 0
            TCTPlayerFrame.elements[i]:SetScript("OnUpdate", function(fr, e) 
            fr.timer = fr.timer+e
                if TCTPlayerFrame.elements[i].timer > 1 then
                    if not fr.tex:GetTexture() then fr:SetAlpha(0) end
                    fr.timer = 0
                    fr:SetScript("OnUpdate", nil)
                end
            end)
        end
    elseif unit == "party1" then
--  print("Updating Party 1")
        for i=11,14 do
            NotifyInspect("party1")
            local itemID = GetInventoryItemID(unit, i)
            if itemID then
        --  print("we found items for party1 inventory slot: "..i)
                if TCTParty1Frame.elements[i].id ~= itemID then
                    TCTParty1Frame.elements[i].tex:SetTexture(nil)
                    TCTPlayerFrame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
                    TCTParty1Frame.elements[i].id = itemID
                    local icon = GetItemIcon(itemID)
                        if not TCTParty1Frame.elements[i].tex:GetTexture() and contains(rings,itemID) and db["TCTParty1FrameRings"] then
                            TCTParty1Frame.elements[i].tex:SetTexture(icon)
                            TCTParty1Frame.elements[i]:SetAlpha(1)
                        elseif not TCTParty1Frame.elements[i].tex:GetTexture() and i>12 then
                            TCTParty1Frame.elements[i].tex:SetTexture(icon)
                            TCTParty1Frame.elements[i].cd2:Hide()
                            TCTParty1Frame.elements[i].cd2:SetAlpha(0)
                            TCTParty1Frame.elements[i].cd2:SetCooldown(0,0)
                            TCTParty1Frame.elements[i]:SetAlpha(1)
                        elseif not TCTParty1Frame.elements[i].tex:GetTexture() then
                        TCTParty1Frame.elements[i]:SetAlpha(0)
                    end
                end
            end
            TCTParty1Frame.elements[i].timer = 0
            TCTParty1Frame.elements[i]:SetScript("OnUpdate", function(fr, e) 
            fr.timer = fr.timer+e
                if TCTParty1Frame.elements[i].timer > 1 then
                    if not fr.tex:GetTexture() then fr:SetAlpha(0) end
                    fr.timer = 0
                    fr:SetScript("OnUpdate", nil)
                end
            end)
        end
    elseif unit == "party2" then
--print("Updating Party 2")
        for i=11,14 do
            NotifyInspect("party2")
            local itemID = GetInventoryItemID(unit, i)
            if itemID then
            --print("we found items for party2 in inventory slot: "..i)
                if TCTParty2Frame.elements[i].id ~= itemID then
                    TCTParty2Frame.elements[i].tex:SetTexture(nil)
                    TCTParty2Frame.elements[i].id = itemID
                    local icon = GetItemIcon(itemID)
                        if not TCTParty2Frame.elements[i].tex:GetTexture() and contains(rings,itemID) and db["TCTParty2FrameRings"] then
                            TCTParty2Frame.elements[i].tex:SetTexture(icon)
                            TCTParty2Frame.elements[i]:SetAlpha(1)
                        elseif not TCTParty2Frame.elements[i].tex:GetTexture() and i>12 then
                            TCTParty2Frame.elements[i].tex:SetTexture(icon)
                            TCTParty2Frame.elements[i].cd2:Hide()
                            TCTParty2Frame.elements[i].cd2:SetAlpha(0)
                            TCTParty2Frame.elements[i].cd2:SetCooldown(0,0)
                            TCTParty2Frame.elements[i]:SetAlpha(1)
                        elseif not TCTParty2Frame.elements[i].tex:GetTexture() then
                        TCTParty2Frame.elements[i]:SetAlpha(0)
                    end
                end
            end
            TCTParty2Frame.elements[i].timer = 0
            TCTParty2Frame.elements[i]:SetScript("OnUpdate", function(fr, e) 
            fr.timer = fr.timer+e
                if TCTParty2Frame.elements[i].timer > 1 then
                    if not fr.tex:GetTexture() then fr:SetAlpha(0) end
                    fr.timer = 0
                    fr:SetScript("OnUpdate", nil)
                end
            end)
        end
    end
    TCTFrame:ShoworHideFrames()
end
function TCTFrame:ZONE_CHANGED_NEW_AREA()
    local type = select(2, IsInInstance())
    if (type == "arena") then
        --Find Bracket
        local bracket
        for i=1, MAX_BATTLEFIELD_QUEUES do
            local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
            if (status == "active" and teamSize > 0) then
                bracket = teamSize
                break
            elseif status == "active" and teamsize == 0 then
                bracket = 3
                break
            end
        end
        
        inArena = true
    for i = 11,14 do
        TCTPlayerFrame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
        TCTPlayerFrame.elements[i].cd2:SetCooldown(0,0)
    end
    for i=13,14 do
        TCTArena1Frame.elements[i].tex:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
        TCTArena1Frame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
        TCTArena1Frame.elements[i]:SetAlpha(1)
        TCTArena2Frame.elements[i].tex:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
        TCTArena2Frame.elements[i]:GetParent():SetBackdropBorderColor(.1,.6,.1)
        TCTArena2Frame.elements[i]:SetAlpha(1)
        if bracket == 3 then
            TCTArena3Frame.elements[i].tex:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
            TCTArena3Frame.elements[i]:GetParent():SetBackdropBorderColor(.1,.6,.1)
            TCTArena3Frame.elements[i]:SetAlpha(1)
        end
    end
    elseif (type ~= "arena" and instanceType == "arena") then
        inArena = false
        for i=11,14 do
            TCTArena1Frame.elements[i].tex:SetTexture(nil)
            TCTArena1Frame.elements[i].cd2:SetCooldown(0,0)
            TCTArena1Frame.elements[i]:SetAlpha(0)
            TCTArena1Frame.elements[i].id = nil
            TCTArena2Frame.elements[i].tex:SetTexture(nil)
            TCTArena2Frame.elements[i]:SetAlpha(0)
            TCTArena2Frame.elements[i].cd2:SetCooldown(0,0)
            TCTArena2Frame.elements[i].id = nil
            TCTArena3Frame.elements[i].tex:SetTexture(nil)
            TCTArena3Frame.elements[i].cd2:SetCooldown(0,0)
            TCTArena3Frame.elements[i]:SetAlpha(0)
            TCTArena3Frame.elements[i].id = nil
        end
        for i=1,3 do
            arenaGUID[i] = nil
        end
    end
    instanceType = type
    self:UpdateIcon("party1")
    self:UpdateIcon("party2")
end

function TCTFrame:UNIT_INVENTORY_CHANGED(_,unit)
    if unit ~= "player" and unit ~= "arena1" and unit ~= "arena2" and unit ~= "arena3" then
        self:UpdateIcon(unit)
    end
end
function TCTFrame:PLAYER_EQUIPMENT_CHANGED(_,slot)
    if slot == 13 or slot == 14 or slot == 11 or slot == 12 then
        self:UpdateIcon("player")
    end
end
function TCTFrame:GROUP_ROSTER_UPDATE()
--print("PARTY MEMBERS CHANGED")
    --Find Bracket
    if inArena == true then
        local bracket
        for i=1, MAX_BATTLEFIELD_QUEUES do
            local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
            if (status == "active" and teamSize > 0) then
                bracket = teamSize
                break
            elseif status == "active" and teamsize == 0 then
                bracket = 3
                break
            end
        end
    end
    for i = 13,14 do 
        if bracket == 3 and not TCTArena3Frame.elements[i].id == nil then
            TCTArena3Frame.elements[i].tex:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
            TCTArena3Frame.elements[i]:GetParent():SetBackdropBorderColor(.1,.6,.1)
            TCTArena3Frame.elements[i]:SetAlpha(1)
        end 
    end
    if party1GUID ~= UnitGUID("party1") then 
    --print("NEW PARTY 1")
        party1GUID = UnitGUID("party1")
        for i=11,14 do
            TCTParty1Frame.elements[i].tex:SetTexture(nil)
            TCTParty1Frame.elements[i].id = nil
            TCTParty1Frame.elements[i]:SetAlpha(0)
            TCTParty1Frame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
        end
        TCTFrame:wait(4,function() TCTFrame:UpdateIcon("party1") end)
        
    end
    if party2GUID ~= UnitGUID("party2") then 
    --print("NEW PARTY 2")
        party2GUID = UnitGUID("party2")
        for i=11,14 do
            TCTParty2Frame.elements[i].tex:SetTexture(nil)
            TCTParty2Frame.elements[i].id = nil
            TCTParty2Frame.elements[i]:SetAlpha(0)
            TCTParty2Frame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
        end
        TCTFrame:wait(4,function() TCTFrame:UpdateIcon("party2") end)
        --self:UpdateIcon("party2")
    end
end
function TCTFrame:PLAYER_LOGIN()
    self:CreateHolder()
    if IsLoggedIn() then
        TCTFrame:ZONE_CHANGED_NEW_AREA()
    end
    self:UpdateIcon("player")
    self:UpdateIcon("party1")
    self:UpdateIcon("party2")
    
    print("TCT LOADED - TYPE /TCT for more options")
    
end

function TCTFrame:Proc(itemID, spellID, GetTime, duration, unit)
    if unit == "player" then
        --PLAYER
        for i=11, 14 do
            local id = TCTPlayerFrame.elements[i].id
            local buffname, rank = GetSpellInfo(spellID)
            if itemID==id then
                if(duration>0) then 
                    TCTPlayerFrame.elements[i].cd2:SetScript("OnHide", function(fr) fr:GetParent():SetBackdropBorderColor(.1,.6,.1) end)
                    TCTPlayerFrame.elements[i]:SetBackdropBorderColor(1,1,0)
                    TCTPlayerFrame.elements[i].cd2:SetCooldown(GetTime, duration)
                    TCTPlayerFrame.elements[i].cd2.UNIT_AURA = function(self, _unit)
                        if (unit ~= _unit) then return end

                        local notFound = true
                        local _i = 1
                        for _i = 1, 40 do
                            local name = UnitAura(unit, _i)
                            if (name == buffname) then
                                notFound = false
                            end
                        end

                        if notFound == true then
                            self:SetReverse(false)
                            self:GetParent():SetBackdropBorderColor(.8,.2,.2)
                            self:UnregisterEvent("UNIT_AURA")
                        end
                    end
                    TCTPlayerFrame.elements[i].cd2:SetScript("OnEvent", function(_self, _event, ...)
                        _self[_event](_self, ...)
                    end)
                    TCTPlayerFrame.elements[i].cd2:RegisterEvent("UNIT_AURA")
                end
            end
        end
    elseif unit == "party1" then
        --PARTY1
    --[[    local x
        if not contains(rings, itemID) then 
            if not TCTParty1Frame.elements[13].id then  x = 13 elseif not TCTParty1Frame.elements[14].id then x = 14 elseif TCTParty1Frame.elements[14].id == itemID then x = 14 end
            if x then
                    local icon = GetItemIcon(itemID) 
                    if icon == nil then print("Icon for"..itemID.." not found, caching and will work next time.") end
                    TCTParty1Frame.elements[x].id = itemID              
                    TCTParty1Frame.elements[x].tex:SetTexture(icon)
                    TCTParty1Frame.elements[x].cd2:Hide()
                    TCTParty1Frame.elements[x].cd2:SetAlpha(0)
                    TCTParty1Frame.elements[x].cd2:SetCooldown(0,0)
                    --TCTArena1Frame.elements[x]:SetBackdropBorderColor(.1,.6,.1)
                    TCTParty1Frame.elements[x]:SetAlpha(1) 
            end
        end--]]
        for i=11, 14 do
            local id = TCTParty1Frame.elements[i].id
            local buffname = GetSpellInfo(spellID)
            if itemID==id then
                if(duration>0) then 
                    TCTParty1Frame.elements[i].cd2:SetScript("OnHide", function(fr) fr:GetParent():SetBackdropBorderColor(.1,.6,.1) end)
                    TCTParty1Frame.elements[i]:SetBackdropBorderColor(1,1,0)
                    TCTParty1Frame.elements[i].cd2:SetCooldown(GetTime, duration)

                    TCTParty1Frame.elements[i].cd2.UNIT_AURA = function(self, _unit)
                        if (unit ~= _unit) then return end

                        local notFound = true
                        local _i = 1
                        for _i = 1, 40 do
                            local name = UnitAura(unit, _i)
                            if (name == buffname) then
                                notFound = false
                            end
                        end

                        if notFound == true then
                            self:SetReverse(false)
                            self:GetParent():SetBackdropBorderColor(.8,.2,.2)
                            self:UnregisterEvent("UNIT_AURA")
                        end
                    end
                    TCTParty1Frame.elements[i].cd2:SetScript("OnEvent", function(_self, _event, ...)
                        _self[_event](_self, ...)
                    end)
                    TCTParty1Frame.elements[i].cd2:RegisterEvent("UNIT_AURA")
                end
            end
        end
    elseif unit == "party2"  then
        --PARTY2
    --[[    local x
        if not contains(rings, itemID) then 
            if not TCTParty2Frame.elements[13].id then  x = 13 elseif TCTParty2Frame.elements[13].id == itemID then x = 13  elseif not TCTParty2Frame.elements[14].id then x = 14 elseif TCTParty2Frame.elements[14].id == itemID then x = 14 else print("This shouldnt happen?") x = 11 end
                    local icon = GetItemIcon(itemID) 
                    if icon == nil then print("Icon for"..itemID.." not found, caching and will work next time.") end
                    TCTParty2Frame.elements[x].id = itemID              
                    TCTParty2Frame.elements[x].tex:SetTexture(icon)
                    TCTParty2Frame.elements[x].cd2:Hide()
                    TCTParty2Frame.elements[x].cd2:SetAlpha(0)
                    TCTParty2Frame.elements[x].cd2:SetCooldown(0,0)
                    --TCTArena1Frame.elements[x]:SetBackdropBorderColor(.1,.6,.1)
                    TCTParty2Frame.elements[x]:SetAlpha(1) 
        end--]]
        for i=11, 14 do
            local id = TCTParty2Frame.elements[i].id
            local buffname = GetSpellInfo(spellID)
            if itemID==id then
                if(duration>0) then 
                    TCTParty2Frame.elements[i].cd2:SetScript("OnHide", function(fr) fr:GetParent():SetBackdropBorderColor(.1,.6,.1) end)
                    TCTParty2Frame.elements[i]:SetBackdropBorderColor(1,1,0)
                    TCTParty2Frame.elements[i].cd2:SetCooldown(GetTime, duration)

                    TCTParty2Frame.elements[i].cd2.UNIT_AURA = function(self, _unit)
                        if (unit ~= _unit) then return end

                        local notFound = true
                        local _i = 1
                        for _i = 1, 40 do
                            local name = UnitAura(unit, _i)
                            if (name == buffname) then
                                notFound = false
                            end
                        end

                        if notFound == true then
                            self:SetReverse(false)
                            self:GetParent():SetBackdropBorderColor(.8,.2,.2)
                            self:UnregisterEvent("UNIT_AURA")
                        end
                    end
                    TCTParty2Frame.elements[i].cd2:SetScript("OnEvent", function(_self, _event, ...)
                        _self[_event](_self, ...)
                    end)
                    TCTParty2Frame.elements[i].cd2:RegisterEvent("UNIT_AURA")
                end
            end
        end
    elseif unit == "arena1"  then
        --ARENA1
        local i
        if not contains(rings, itemID) then 
            if not TCTArena1Frame.elements[13].id then  i = 13 elseif TCTArena1Frame.elements[13].id == itemID then i = 13  else i = 14 end
                    local icon = GetItemIcon(itemID) 
                    if icon == nil then print("Icon for"..itemID.." not found, caching and will work next time.") end
                    TCTArena1Frame.elements[i].id = itemID              
                    TCTArena1Frame.elements[i].tex:SetTexture(icon)
                    TCTArena1Frame.elements[i].cd2:Hide()
                    TCTArena1Frame.elements[i].cd2:SetAlpha(0)
                    TCTArena1Frame.elements[i].cd2:SetCooldown(0,0)
                    --TCTArena1Frame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
                    TCTArena1Frame.elements[i]:SetAlpha(1) 
            local id = TCTArena1Frame.elements[i].id
            local buffname = GetSpellInfo(spellID)
            if itemID==id then
                TCTArena1Frame.elements[i].cd2:SetAlpha(0)
                TCTArena1Frame.elements[i].cd2:SetScript("OnHide", function(fr) fr:GetParent():SetBackdropBorderColor(.1,.6,.1) end)
                if(duration>0) then 
                    TCTArena1Frame.elements[i].cd2:SetCooldown(GetTime, duration - 0.5)
                    TCTArena1Frame.elements[i]:SetBackdropBorderColor(1,1,0)

                    TCTArena1Frame.elements[i].cd2.UNIT_AURA = function(self, _unit)
                        if (unit ~= _unit) then return end

                        local notFound = true
                        local _i = 1
                        for _i = 1, 40 do
                            local name = UnitAura(unit, _i)
                            if (name == buffname) then
                                notFound = false
                            end
                        end

                        if notFound == true then
                            self:SetReverse(false)
                            self:GetParent():SetBackdropBorderColor(.8,.2,.2)
                            self:UnregisterEvent("UNIT_AURA")
                        end
                    end
                    TCTArena1Frame.elements[i].cd2:SetScript("OnEvent", function(_self, _event, ...)
                        _self[_event](_self, ...)
                    end)
                    TCTArena1Frame.elements[i].cd2:RegisterEvent("UNIT_AURA")
                end
            end
        end
    elseif unit == "arena2" then
        --ARENA2
        local i
        if not contains(rings, itemID) then 
            if not TCTArena2Frame.elements[13].id then  i = 13 elseif TCTArena2Frame.elements[13].id == itemID then i = 13  else i = 14 end
                    local icon = GetItemIcon(itemID) 
                    if icon == nil then print("Icon for"..itemID.." not found, caching and will work next time.") end
                    TCTArena2Frame.elements[i].id = itemID              
                    TCTArena2Frame.elements[i].tex:SetTexture(icon)
                    TCTArena2Frame.elements[i].cd2:Hide()
                    TCTArena2Frame.elements[i].cd2:SetAlpha(0)
                    TCTArena2Frame.elements[i].cd2:SetCooldown(0,0)
                    --TCTArena2Frame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
                    TCTArena2Frame.elements[i]:SetAlpha(1) 
            local id = TCTArena2Frame.elements[i].id
            local buffname = GetSpellInfo(spellID)
            if itemID==id then
                TCTArena2Frame.elements[i].cd2:SetAlpha(0)
                TCTArena2Frame.elements[i].cd2:SetScript("OnHide", function(fr) fr:GetParent():SetBackdropBorderColor(.1,.6,.1) end)
                if(duration>0) then 
                    TCTArena2Frame.elements[i].cd2:SetCooldown(GetTime, duration - 0.5)
                    TCTArena2Frame.elements[i]:SetBackdropBorderColor(1,1,0)

                    TCTArena2Frame.elements[i].cd2.UNIT_AURA = function(self, _unit)
                        if (unit ~= _unit) then return end

                        local notFound = true
                        local _i = 1
                        for _i = 1, 40 do
                            local name = UnitAura(unit, _i)
                            if (name == buffname) then
                                notFound = false
                            end
                        end

                        if notFound == true then
                            self:SetReverse(false)
                            self:GetParent():SetBackdropBorderColor(.8,.2,.2)
                            self:UnregisterEvent("UNIT_AURA")
                        end
                    end
                    TCTArena2Frame.elements[i].cd2:SetScript("OnEvent", function(_self, _event, ...)
                        _self[_event](_self, ...)
                    end)
                    TCTArena2Frame.elements[i].cd2:RegisterEvent("UNIT_AURA")
                end
            end
        end
    elseif unit == "arena3" then
        --ARENA3
        local i
        if not contains(rings, itemID) then 
            if not TCTArena3Frame.elements[13].id then  i = 13 elseif TCTArena3Frame.elements[13].id == itemID then i = 13  else i = 14 end
                    local icon = GetItemIcon(itemID) 
                    if icon == nil then print("Icon for"..itemID.." not found, caching and will work next time.") end
                    TCTArena3Frame.elements[i].id = itemID              
                    TCTArena3Frame.elements[i].tex:SetTexture(icon)
                    TCTArena3Frame.elements[i].cd2:Hide()
                    TCTArena3Frame.elements[i].cd2:SetAlpha(0)
                    TCTArena3Frame.elements[i].cd2:SetCooldown(0,0)
                    --TCTArena3Frame.elements[i]:SetBackdropBorderColor(.1,.6,.1)
                    TCTArena3Frame.elements[i]:SetAlpha(1) 
            local id = TCTArena3Frame.elements[i].id
            local buffname = GetSpellInfo(spellID)
            if itemID==id then
                TCTArena3Frame.elements[i].cd2:SetAlpha(0)
                TCTArena3Frame.elements[i].cd2:SetScript("OnHide", function(fr) fr:GetParent():SetBackdropBorderColor(.1,.6,.1) end)
                if(duration>0) then 
                    TCTArena3Frame.elements[i].cd2:SetCooldown(GetTime, duration - 0.5)
                    TCTArena3Frame.elements[i]:SetBackdropBorderColor(1,1,0)
                    TCTArena3Frame.elements[i].cd2.UNIT_AURA = function(self, _unit)
                        if (unit ~= _unit) then return end

                        local notFound = true
                        local _i = 1
                        for _i = 1, 40 do
                            local name = UnitAura(unit, _i)
                            if (name == buffname) then
                                notFound = false
                            end
                        end

                        if notFound == true then
                            self:SetReverse(false)
                            self:GetParent():SetBackdropBorderColor(.8,.2,.2)
                            self:UnregisterEvent("UNIT_AURA")
                        end
                    end
                    TCTArena3Frame.elements[i].cd2:SetScript("OnEvent", function(_self, _event, ...)
                        _self[_event](_self, ...)
                    end)
                    TCTArena3Frame.elements[i].cd2:RegisterEvent("UNIT_AURA")
                end
            end
        end
    end
    TCTFrame:ShoworHideFrames()
end
local waitTable = {};
local waitFrame = nil;

function TCTFrame:wait(delay, func, ...)
--print("waiting "..delay.." seconds")
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent, "BackdropTemplate");
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end