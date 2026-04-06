KeySpinner = LibStub("AceAddon-3.0"):NewAddon("KeySpinner", "AceComm-3.0",  "AceConsole-3.0",  "AceSerializer-3.0")
local LibKeystone = LibStub("LibKeystone")

KeySpinner:RegisterChatCommand("spin", "ToggleUI")

-----------------------------------------------------------------------
-- OnInitialize - Build the UI
-----------------------------------------------------------------------
function KeySpinner:OnInitialize()
    LibKeystone.Register(self, function(keyLevel, keyMapID, playerRating, playerName, channel)
    	self:NewKeyData(playerName, keyMapID, keyLevel)
    end)
    KeySpinner:RegisterComm("KeySpinner")

    KeySpinner.KeyData = {}
    KeySpinner.UnitMap = {"player", "party1", "party2", "party3", "party4"}

    -- Build the key selection frame
    self.Frame = CreateFrame("Frame", "KeySpinnerFrame", UIParent, "BasicFrameTemplateWithInset")
    self.Frame:SetSize(600, 300)
    self.Frame:SetPoint("CENTER", "UIParent", "CENTER")
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

    -- Create the results/spinner text frame
    self.ResultsFrame = CreateFrame("Frame", "KeySpinnerResultsFrame", UIParent)
    self.ResultsText = self.ResultsFrame:CreateFontString(nil, "OVERLAY")
    self.ResultsText:SetFont("Fonts\\FRIZQT__.TTF", 32)
    self.ResultsText:SetPoint("CENTER", "UIParent", "CENTER", 0, 300)
    self.ResultsFrame:HookScript("OnUpdate", function(self, elapsed) KeySpinner:ResultsUpdate(elapsed) end)
    self.ResultsFrame:Hide()

    -- Various varialbes to hanle spinning
    self.NextUpdate = 0 -- Elapsed time until animating the next "frame"
    self.ResPointer = 0
    self.SpinPhase = 0
    self.SpinTable = nil
    self.SpinMax = 10 -- Max seconds to spend in the "spinning" portion of the animation
    self.SpinTotal = 0 -- Total time spent in the "spinning" portion of the animation
    self.TotalTime = 0 -- Time in current animation phase
end

-----------------------------------------------------------------------
-- ToggleUI - React to /spin command
-----------------------------------------------------------------------
function KeySpinner:ToggleUI()
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self:Refresh_Click()
        self:UpdateKeyList()
        self.Frame:Show()
    end
end

-----------------------------------------------------------------------
-- Refresh_Click - Refresh button clicked. Update keystone information
-----------------------------------------------------------------------
function KeySpinner:Refresh_Click()
    self.KeyData = {}
    LibKeystone.Request("PARTY")
end

-----------------------------------------------------------------------
-- NewKeyData - LibKeystone callback. Update keystone information
-----------------------------------------------------------------------
function KeySpinner:NewKeyData(playerName, keyMapID, keyLevel)
    KeyName = C_ChallengeMode.GetMapUIInfo(keyMapID)
    self.KeyData[playerName] = KeyName .. " +" .. keyLevel
    self:UpdateKeyList()
end

-----------------------------------------------------------------------
-- UpdateKeyList - Update the GUI with the latest keystone data
-----------------------------------------------------------------------
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

-----------------------------------------------------------------------
-- Spin_Click - Spin button clicked. Build and send spin command message
-----------------------------------------------------------------------
function KeySpinner:Spin_Click()
    local test = false

    if test then

        local Msg = {}
        Msg.Options = {}
        -- Generate some fake data
        for i=1,5 do
            table.insert(Msg.Options, {Name="Potato " .. i, Key="DoomTown"})
        end
        Msg.Selected = math.random(#Msg.Options)
        local MsgStr = self:Serialize(Msg)

        -- send it to myself
        self:SendCommMessage("KeySpinner", MsgStr, "WHISPER", UnitName("player"))
    else
        local Checked = {}

        for i=1,5 do
            if (self.CheckBoxes[i]:GetChecked()) then
                table.insert(Checked, self.UnitMap[i])
            end
        end
        local selected = math.random(#Checked)

        if (#Checked == 0) then
            print ("No keys selected")
            return
        end

        --Build the message
        local Msg = {}
        Msg.Selected = selected
        Msg.Options = {}
        for i=1,#Checked do
            local name, _ = UnitName(Checked[i])
            if (self.KeyData[name]) then
                key = self.KeyData[name]
            else
                key = "Unknown Key"
            end
            table.insert(Msg.Options, {Name=name, Key=key})
        end
        local MsgStr = self:Serialize(Msg)

        self:SendCommMessage("KeySpinner", MsgStr, "PARTY")

    end

    self.Frame:Hide()

end

-----------------------------------------------------------------------
-- OnCommReceived - Handle incoming spin command
-----------------------------------------------------------------------
function KeySpinner:OnCommReceived(prefix, message, distribution, sender)
    local Valid, Msg = self:Deserialize(message)
    if (not Valid) then
        print("KeySpinner: Something went wriong with the spin message...")
        return
    end

    -- New Spin Message received. Clean up old animation
    self.ResultsText:SetText("")
    self.NextUpdate = 0.0

    -- Kick off new animation
    self.SpinTable = Msg
    self.SpinPhase = 1;
    self.ResultsFrame:Show();


end



-----------------------------------------------------------------------
-- ResultsUpdate - ResultsFrame's OnUpdate handler.
-- Animate a spin, in an awful way.
-- Stages 1-3: inital text
-- Stage 4: Set up to spin
-- Stage 5: Spin, with a progressively longer udpate rate to simulate
--          drag on the "wheel"
-- Stage 6: Show winner
-- Stage 7: Cleanup
-----------------------------------------------------------------------
function KeySpinner:ResultsUpdate(deltaTime)
    self.TotalTime = self.TotalTime + deltaTime
    if self.TotalTime > self.NextUpdate then
        if self.SpinPhase == 1 then
            self.ResultsText:SetText("HERE")
            PlaySoundFile(567474)

            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 1.0
        elseif self.SpinPhase == 2 then
            self.ResultsText:SetText("WE")
            PlaySoundFile(567474)

            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 1.0
        elseif self.SpinPhase == 3 then
            self.ResultsText:SetText("GO")
            PlaySoundFile(567474)

            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 1.0
        elseif self.SpinPhase == 4 then
            -- Set up spin
            self.SpinTotal = 0
            self.ResPointer = math.random(#self.SpinTable.Options)

            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 0.1
        elseif self.SpinPhase == 5 then
            -- We're spinning
            self.SpinTotal = self.SpinTotal + self.TotalTime
            local Progress = math.min(1, self.SpinTotal / self.SpinMax)

            -- Increment brackets to next item
            self.ResPointer = self.ResPointer + 1
            if self.ResPointer > #self.SpinTable.Options then
                self.ResPointer = 1
            end

            -- Tick
            PlaySoundFile(4214070)

            -- Redraw the text
            local OutStr = ""
            for i=1,#self.SpinTable.Options do
                if i == self.ResPointer then
                    OutStr = OutStr .. string.format(">%s's %s<\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                else
                    OutStr = OutStr .. string.format("%s's %s\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                end
            end
            self.ResultsText:SetText(OutStr)

            -- Set NextUpdate to simulate a wheel slowing down
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

        elseif self.SpinPhase == 6 then
            -- Spin complete

            -- Completion sounds
            PlaySoundFile(568672)
            PlaySoundFile(567499)

            -- Redraw text with winner hilighted in green
            local OutStr = ""
            for i=1,#self.SpinTable.Options do
                if i == self.ResPointer then
                    OutStr = OutStr .. string.format("|cff00ff00>%s's %s<|r\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                else
                    OutStr = OutStr .. string.format("%s's %s\n", self.SpinTable.Options[i].Name, self.SpinTable.Options[i].Key)
                end
            end
            self.ResultsText:SetText(OutStr)

            -- Send result to chat
            if UnitIsGroupLeader("player") then
                local Winner = self.SpinTable.Options[spin.Selected]
                SendChatMessage(string.format("We have a winner! %s's %s", Winner.Name, Winner.Key), "PARTY")
            end


            self.SpinPhase = self.SpinPhase + 1
            self.NextUpdate = 5.0

        else
            -- We're done, clean up a bit
            self.SpinTable = nil
            self.SpinPhase = 0
            self.ResultsFrame:Hide()
        end
        self.TotalTime = 0
    end
end
