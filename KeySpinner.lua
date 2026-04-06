KeySpinner = LibStub("AceAddon-3.0"):NewAddon("KeySpinner", "AceComm-3.0",  "AceConsole-3.0",  "AceSerializer-3.0")
local LibKeystone = LibStub("LibKeystone")

KeySpinner:RegisterChatCommand("spin", "OpenUI")

function KeySpinner:OnInitialize()
    LibKeystone.Register(self, function(keyLevel, keyMapID, playerRating, playerName, channel)
    	self:NewKeyData(playerName, keyMapID, keyLevel)
    end)
    KeySpinner:RegisterComm("KeySpinner")

    KeySpinner.KeyData = {}
    KeySpinner.UnitMap = {"player", "party1", "party2", "party3", "party4"}

    self.FrameX = 0
    self.FrameY = 0
    self.TotalTime = 0
    self.ResPointer = 0
    self.SpinTable = nil
    self.SpinPhase = 0
    self.NextUpdate = 0
    self.SpinTotal = 0
    self.SpinMax = 10


    self.Frame = CreateFrame("Frame", "KeySpinnerFrame", UIParent, "BasicFrameTemplateWithInset")
    self.Frame:SetSize(600, 300)
    self.Frame:SetPoint("CENTER", "UIParent", "CENTER", self.FrameX, self.FrameY)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetClampedToScreen(true)
    self.Frame:SetFrameStrata("DIALOG")

    self.Frame.TitleBg:SetHeight(30)
    self.Frame.Title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.Frame.Title:SetPoint("TOPLEFT", self.Frame.TitleBg, "TOPLEFT", 5, -5)
    self.Frame.Title:SetText("KeySpinner - Select Keys")


    self.Frame:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)

    self.Frame:SetScript("OnDragStop", function(frame)
      frame:StopMovingOrSizing()
      _, _, _, KeySpinner.FrameX, KeySpinner.FrameY = frame:GetPoint(1)
    end)

    local Button = CreateFrame("Button", "KeySpinnerSpinButton", self.Frame, "UIPanelButtonTemplate")
    Button:SetPoint ("BOTTOMRIGHT", self.Frame, "BOTTOMRIGHT", -10, 10)
    Button:SetSize(100, 30)
    Button:SetText("Spin it!")
    Button:SetScript("OnClick", function() KeySpinner:Spin_Click() end)

    Button = CreateFrame("Button", "KeySpinnerRefreshButton", self.Frame, "UIPanelButtonTemplate")
    Button:SetPoint ("BOTTOMRIGHT", self.Frame, "BOTTOMRIGHT", -120, 10)
    Button:SetSize(100, 30)
    Button:SetText("Refresh Keys")
    Button:SetScript("OnClick", function() KeySpinner:Refresh_Click() end)

    --Create Checkboxes
    self.CheckBoxes = {}
    for i=1,5 do
    	self.CheckBoxes[i] = CreateFrame("CheckButton", nil, KeySpinner.Frame, "InterfaceOptionsCheckButtonTemplate")
        self.CheckBoxes[i]:SetPoint("TOPLEFT", 20, i * -40)
        self.CheckBoxes[i].text:SetFont("Fonts\\FRIZQT__.TTF", 24, "")
        self.CheckBoxes[i]:Hide()
    end

    self.Frame:Hide()

    self.ResultsText  = UIParent:CreateFontString(nil, "OVERLAY")
    self.ResultsText:SetFont("Fonts\\FRIZQT__.TTF", 24)
    self.ResultsText:SetPoint("CENTER", "UIParent", "CENTER", 0, 300)
    self.Frame:HookScript("OnUpdate", function(self, elapsed) KeySpinner:ResultsUpdate(elapsed) end)

    self.ResultsText:Hide()
end

function KeySpinner:ResultsUpdate(deltaTime)
    if self.SpinPhase == 0 then
        return
    end

    self.TotalTime = self.TotalTime + deltaTime
    if self.TotalTime > self.NextUpdate then
        if self.SpinPhase == 1 then
            self.ResultsText:SetText("HERE")
            PlaySoundFile(567474)
            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 1.0
        elseif self.SpinPhase == 2 then
            self.ResultsText:SetText("HERE\nWE")
            PlaySoundFile(567474)
            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 1.0
        elseif self.SpinPhase == 3 then
            self.ResultsText:SetText("HERE\nWE\nGO")
            PlaySoundFile(567474)
            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 1.0
        elseif self.SpinPhase == 4 then
            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 0.1
        elseif self.SpinPhase == 5 then
            -- We're spinning
            self.SpinTotal = self.SpinTotal + self.TotalTime
            local Progress = math.min(1, self.SpinTotal / self.SpinMax)

            self.ResPointer = self.ResPointer + 1
            -- Be smarter here
            if self.ResPointer > #self.SpinTable.Options then
                self.ResPointer = 1
            end

            local OutStr = ""
            for i=1,#self.SpinTable.Options do
                if i == self.ResPointer then
                    OutStr = OutStr .. string.format(">%s's %s<\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                else
                    OutStr = OutStr .. string.format("%s's %s\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                end
            end
            self.ResultsText:SetText(OutStr)
            if Progress == 1 then
                self.NextUpdate = 1
                if self.ResPointer == self.SpinTable.Selected then
                    self.SpinPhase = self.SpinPhase + 1
                    self.NextUpdate = 0.25
                end
            elseif Progress < 0.5 then
                self.NextUpdate = 2 ^ (20 * Progress - 10) / 2
                self.NextUpdate = math.max(self.NextUpdate, 0.06)
            else
                self.NextUpdate = (2 - 2 ^ (-20 * Progress + 10)) / 2
            end
            PlaySoundFile(4214070)
            --print(string.format("Next update at %0.3f, SpinTotal = %0.3f, self.TotalTime = %0.3f, Progress = %0.3f", self.NextUpdate, self.SpinTotal, self.TotalTime, Progress))
        elseif self.SpinPhase == 6 then
            -- We're done!
            self.SpinTotal = 0.0
            PlaySoundFile(568672)
            PlaySoundFile(567499)
            local OutStr = ""
            for i=1,#self.SpinTable.Options do
                if i == self.ResPointer then
                    OutStr = OutStr .. string.format("|cff00ff00>%s's %s<|r\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                else
                    OutStr = OutStr .. string.format("%s's %s\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                end
            end
            self.ResultsText:SetText(OutStr)
            if UnitIsGroupLeader("self") then
                local Winner = self.SpinTable.Options[spin.Selected]
                SendChatMessage(string.format("We have a winner! %s's %s", Winner.Name, Winner.Key), "PARTY")
            end
            self.NextUpdate = 5.0
            self.SpinPhase = self.SpinPhase + 1
        else
            self.SpinTable = nil
            self.SpinPhase = 0
            self.ResultsText:Hide()
        end
        self.TotalTime = 0
    end
end

function KeySpinner:OnCommReceived(prefix, message, distribution, sender)
    local Valid, Msg = self:Deserialize(message)
    if (not Valid) then
        print("KeySpinner: Something went wriong with the spin message...")
        return
    end

    self.SpinTable = Msg
    self.SpinPhase = 1;
    self.NextUpdate = 0.0
    self.ResultsText:SetText("")
    self.ResultsText:Show();

end

function KeySpinner:UpdateKeyList()

    for i=1,5 do
        local unitid = self.UnitMap[i]
        local name, _ = UnitName(unitid)
        if name then
            if (self.KeyData[name]) then
                    key = self.KeyData[name]
                else
                    key = "Unknown Key"
            end
            self.CheckBoxes[i].text:SetText(name .. " - " .. key)
            self.CheckBoxes[i]:SetChecked(true)
            self.CheckBoxes[i]:Show()
        end
    end
end



function KeySpinner:OpenUI()
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self:Refresh_Click()
        self:UpdateKeyList()
        self.Frame:Show()
    end
end

function KeySpinner:Refresh_Click()
    self.KeyData = {}
    LibKeystone.Request("PARTY")
end

function KeySpinner:Spin_Click()
    -- local Checked = {}

    -- for i=1,5 do
    --     if (self.CheckBoxes[i]:GetChecked()) then
    --         table.insert(Checked, self.UnitMap[i])
    --     end
    -- end
    -- local selected = math.random(#Checked)

    -- if (#Checked == 0) then
    --     print ("No keys selected")
    --     return
    -- end

    -- --Build the message
    -- local Msg = {}
    -- Msg.Selected = selected
    -- Msg.Options = {}
    -- for i=1,#Checked do
    --     local name, _ = UnitName(Checked[i])
    --     if (self.KeyData[name]) then
    --         key = self.KeyData[name]
    --     else
    --         key = "Unknown Key"
    --     end
    --     table.insert(Msg.Options, {Name=name, Key=key})
    -- end
    -- local MsgStr = self:Serialize(Msg)

    -- self:SendCommMessage("KeySpinner", MsgStr, "PARTY")

    -- TEST MODE
    local Msg = {}
    Msg.Options = {}
    for i=1,5 do
        table.insert(Msg.Options, {Name="Potato " .. i, Key="DoomTown"})
    end
    Msg.Selected = math.random(#Msg.Options)
    local MsgStr = self:Serialize(Msg)
    self:SendCommMessage("KeySpinner", MsgStr, "WHISPER", "Teratin")

end

function KeySpinner:NewKeyData(playerName, keyMapID, keyLevel)
    KeyName = C_ChallengeMode.GetMapUIInfo(keyMapID)
    self.KeyData[playerName] = KeyName .. " +" .. keyLevel
    self:UpdateKeyList()
end
