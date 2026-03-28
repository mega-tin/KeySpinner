KeySpinner = LibStub("AceAddon-3.0"):NewAddon("KeySpinner", "AceComm-3.0",  "AceConsole-3.0")

KeySpinner:RegisterChatCommand("spin", "OpenUI")

KeySpinner.KeyData = {}
KeySpinner.UnitMap = {"player", "party1", "party2", "party3", "party4"}
function KeySpinner:OnInitialize()
    self.FrameX = 0
    self.FrameY = 0


    self.Frame = CreateFrame("Frame", "KeySpinnerFrame", UIParent, "BackdropTemplate")
    self.Frame:SetSize(600, 300)
    self.Frame:SetPoint("CENTER", "UIParent", "CENTER", self.FrameX, self.FrameY)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetClampedToScreen(true)
    self.Frame:SetFrameStrata("DIALOG")

    self._normalBackdrop =
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 10,
        edgeSize = 16,
        insets = { left = 2, right = 2, top = 2, bottom = 2}
    }
    self.Frame:SetBackdrop(self._normalBackdrop)
    self.Frame:SetBackdropColor(0.85, 0.0, 1.0)

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
        self:UpdateKeyList()
        self.Frame:Show()
    end
end

function KeySpinner:Refresh_Click()
    self:UpdateKeyList()
end

function KeySpinner:Spin_Click()
    local Checked = {}

    for i=1,5 do
        if (self.CheckBoxes[i]:GetChecked()) then
            table.insert(Checked, self.UnitMap[i])
        end
    end

    if (#Checked == 0) then
        print ("No keys selected")
    else
        local selected = math.random(#Checked)
        local name, _ = UnitName(Checked[selected])
        if (self.KeyData[name]) then
            key = self.KeyData[name]
        else
            key = "Unknown Key"
        end
        print("Selected " .. name .. " - " .. key)
    end

end