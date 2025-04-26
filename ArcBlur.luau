-- Thanks to SomeFedoraGuy (me) for spending a lot more
-- than needed time on writing the math in the Update() function
-- For future use: PBR-124652808947078

local UIBlur = {}
UIBlur.__index = UIBlur

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local DepthOfField = Instance.new("DepthOfFieldEffect")
local Container = Camera:FindFirstChild("UIBlur")

local QualityLevel = UserSettings().GameSettings.SavedQualityLevel

local Offset = 0.05

export type UIBlur = {
	_ScreenGui : ScreenGui,
	_GuiObject : GuiObject,
	_Connections : {RBXScriptConnection},
	_Part : BasePart,
	_BlurEffect : BlurEffect,
	
	_Rendering : boolean,
	
	Update : (UIBlur) -> (),
	Destroy : (UIBlur) -> (),
}

local function IsBlurEffectValid(Blur:BlurEffect)
	if Blur:IsA("BlurEffect") and Blur.Parent:IsA("GuiObject") then
		UIBlur.new(Blur.Parent,nil,Blur.Size == 0)
	end
end
local function CheckForBlurEffect()
	for _,Object:Instance in Player.PlayerGui:GetDescendants() do
		IsBlurEffectValid(Object) 
	end
end
local function GetContainer() : Folder
	if not Container then
		Container = Instance.new("Folder")
		Container.Name = "UIBlur"
		Container.Parent = Camera
	end
	return Container
end
local function PointToRay(Vector:Vector2) : Vector3
	local Ray = Camera:ScreenPointToRay(Vector.X,Vector.Y,Offset)
	return Ray.Origin + Ray.Direction * Offset
end

DepthOfField.Name = "UIBlur"
DepthOfField.FarIntensity = 0
DepthOfField.FocusDistance = 0
DepthOfField.InFocusRadius = 0
DepthOfField.NearIntensity = 1
DepthOfField.Parent = Lighting

function UIBlur.new(GuiObject:GuiObject, DisableBelowNeededGraphics:boolean?) : UIBlur
	if not RunService:IsClient() then return end
	if not GuiObject then return end
	if not DisableBelowNeededGraphics then DisableBelowNeededGraphics = true end
	
	local self = {} :: UIBlur
	
	self._ScreenGui = GuiObject:FindFirstAncestorOfClass("ScreenGui")
	self._GuiObject = GuiObject
	self._Rendering = true
	self._Connections = {}
	self._BlurEffect = GuiObject:FindFirstChildOfClass("BlurEffect")
	
	self._Part = Instance.new("Part")
	self._Part.CastShadow = false
	self._Part.CanCollide = false
	self._Part.CanQuery = false
	self._Part.CanTouch = false
	self._Part.Anchored = true
	self._Part.Material = Enum.Material.Glass
	self._Part.Name = GuiObject.Name
	self._Part.Parent = GetContainer()
	
	table.insert(self._Connections,GuiObject.AncestryChanged:Connect(function()
		if not GuiObject.Parent then
			self:Destroy()
		end
	end))
	
	if DisableBelowNeededGraphics then
		self._Rendering = QualityLevel.Value >= 8 or QualityLevel == Enum.SavedQualitySetting.Automatic
		table.insert(self._Connections,UserSettings().GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
			QualityLevel = UserSettings().GameSettings.SavedQualityLevel
			self._Rendering = QualityLevel.Value >= 8 or QualityLevel == Enum.SavedQualitySetting.Automatic
		end))
	end
	if self._BlurEffect then
		self._BlurEffect.AncestryChanged:Connect(function()
			self:Destroy()
		end)
	end
	
	table.insert(self._Connections,RunService.PreRender:Connect(function()
		self:Update()
	end))
	
	return setmetatable(self,UIBlur)
end

function UIBlur.Update(self: UIBlur)
	local Rendering = self._Rendering and self._GuiObject.Visible and self._ScreenGui.Enabled and (self._BlurEffect and self._BlurEffect.Enabled or not self._BlurEffect)
	
	self._Part.Transparency = Rendering and 0.98 or 1
	if Rendering then
		local GuiPos = self._GuiObject.AbsolutePosition
		local GuiSize = self._GuiObject.AbsoluteSize

		local TopLeft = PointToRay(GuiPos)
		local Center = PointToRay(GuiPos + GuiSize / 2)
		
		
		
		self._Part.Size = Vector3.new((PointToRay(GuiPos + Vector2.xAxis * GuiSize.X) - TopLeft).Magnitude,(PointToRay(GuiPos + Vector2.yAxis * GuiSize.Y) - TopLeft).Magnitude)
		self._Part.CFrame = CFrame.new(Center,Center - Camera.CFrame.LookVector) * CFrame.Angles(0,math.pi,-math.rad(self._GuiObject.AbsoluteRotation))
	end
end

function UIBlur.Destroy(self:UIBlur)
	for _,Connection in self._Connections do
		Connection:Disconnect()
	end
	self._Part:Destroy()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = workspace.CurrentCamera
end)
if script:GetAttribute("AutoAddEnabled") then
	CheckForBlurEffect()
end
Player.PlayerGui.DescendantAdded:Connect(function(Descendant)
	if script:GetAttribute("AutoAddEnabled") then
		IsBlurEffectValid(Descendant)
	end
end)
script:GetAttributeChangedSignal("AutoAddEnabled"):Connect(function()
	if script:GetAttribute("AutoAddEnabled") then
		CheckForBlurEffect()
	end
end)

return UIBlur
