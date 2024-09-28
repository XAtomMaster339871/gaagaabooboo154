--[[
hi there
You've probably stumbled into this by mistake, or are going to steal my code.
If you are, please just give credits back to crowwithagun or crow for short-form.
You don't have to, but it's just nice.
Also, if you end up making money off of this code, I am going to haunt you for eternity. 
ok buh bye lol
]]

local api = {}
local services = {rs = game:GetService("ReplicatedStorage"), plr = game:GetService("Players"), localPlr = game:GetService("Players").LocalPlayer}
local doors = {
	current = workspace.CurrentRooms,
	gameData = services.rs.GameData,
	lights = require(services.rs.ClientModules.Module_Events),
	mainGame = require(game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game),
}
api.Hooks = {
	OnGenerateRoom = Instance.new'BindableEvent',
	OnEnterRoom = Instance.new'BindableEvent',
	OnNodeEntity = Instance.new'BindableEvent',
}
api.Commands = {}
api.Funcs = {
	Hooks = {},
	Doors = {},
}
api.ActiveHooks = {}
api.Connections = {}
api.__index = api
-- HOOKS

function api.Funcs.Hooks:BindToHook(hook: string, name: string, func: (any))
	-- i dont know if executors will recognize this
	--assert(api.Hooks[hook] ~= nil, `"{hook}" is not a valid member of api.Hooks`)
	local bind = api.Hooks[hook].Event:Connect(func)
	api.ActiveHooks[name:lower()] = bind
	return bind, hook
end

function api.Funcs.Hooks:UnbindFromExisting(bind: RBXScriptConnection) 
	bind:Disconnect()
end

function api.Funcs.Hooks:UnbindHook(name: string)
	name = name:lower()
	if api.ActiveHooks[name] then
		api.ActiveHooks[name]:Disconnect()
		api.ActiveHooks[name] = nil
	end
end

function api.Funcs.Hooks:FireHook(hook: string, ...)
	api.Hooks[hook]:Fire(...)
end

api.Connections.DoorOpened = doors.gameData.LatestRoom:GetPropertyChangedSignal('Value'):Connect(function()
	api.Funcs.Hooks:FireHook(
		"OnGenerateRoom", 
		doors.current:FindFirstChild(tostring(doors.gameData.LatestRoom.Value)),
		doors.gameData.LatestRoom.Value
	)
end)

api.Connections.RoomEntered = services.localPlr:GetAttributeChangedSignal('CurrentRoom'):Connect(function()
	if doors.current:FindFirstChild(tostring(services.localPlr:GetAttribute('CurrentRoom'))) then
		api.Funcs.Hooks:FireHook(
			"OnEnterRoom", 
			doors.current:FindFirstChild(tostring(services.localPlr:GetAttribute('CurrentRoom'))), 
			services.localPlr:GetAttribute('CurrentRoom')
		)
	end
end)

api.Connections.MonsterCheckNode = workspace.ChildAdded:Connect(function(c)
	local data = {}
	if c.Name:match('RushMoving') then
		data[1] = (c:GetPivot().Position)-services.localPlr.Character.PrimaryPart.Position
		data[2] = c
		data[3] = "Rush"
	elseif c.Name:match('AmbushMoving') then
		data[1] = (c:GetPivot().Position)-services.localPlr.Character.PrimaryPart.Position
		data[2] = c
		data[3] = "Ambush"
	end
	
	if (data[1] and data[1] <= 200) then
		api.Funcs.Hooks:FireHook("OnNodeEntity", data[3], data[2])
	end 
end)

-- HOOKS END


-- COMMANDS START

function api.Funcs.Doors.Latest(): Model & any
	return workspace.CurrentRooms:FindFirstChild(tostring(doors.gameData.LatestRoom.Value))
end

function api.Funcs.Doors.ForLightsInRoomDo(room, func: (any))
	for _, LightFixture in next, room:GetDescendants() do
		if LightFixture:IsA("BasePart") and LightFixture.Name == "LightFixture" then
			func(LightFixture)
		end
	end
end

function api.Funcs.Doors.caption(txt): ()
	doors.mainGame.caption(txt)
end

function api.Commands.RunInvisibleNodeEntities(t: number): ()
	local hook = api.Funcs.Hooks:BindToHook("OnNodeEntity", "InvisibleEntities", function(entity: Model & unknown, entityName: string)
		for _,inst in pairs(entity:GetDescendants()) do
			if inst:IsA('ParticleEmitter') then
				inst:Destroy()
			end
		end
	end)
	task.delay(t, function()
		api.Funcs.Hooks:UnbindHook("InvisibleEntities")
	end)
end

function api.Commands.BreakLights()
	local current = api.Funcs.Doors.Latest()
	api.Funcs.Doors.ForLightsInRoomDo(current, function(light)
		light:Destroy()
	end)
	--doors.lights.shatter(current)
end



return {
	Hooks = api.Funcs.Hooks,
	Commands = api.Commands,
	Doors = doors,
	Funcs_Doors = api.Funcs.Doors,
}
