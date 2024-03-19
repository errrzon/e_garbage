local npc = Config.npc


local function startJob()
	local isGroupOwner = exports['e_groups']:isGroupOwner()
	print("isGroupOwner? ", isGroupOwner)
	if not isGroupOwner then
		TriggerEvent("e_garbageJob:client:notify", "To start job you have to be a group leader!", "inform")
		return
	end
	local isOccupied = IsPositionOccupied(Config.truck.coords.x, Config.truck.coords.y, Config.truck.coords.z, 10, false,
		true, false, false, false, 0, false)
	print("isSpotOccupied? ", isOccupied)
	if isOccupied then
		TriggerEvent("e_garbageJob:client:notify", "Some vehicle is already on truck spawn location", "inform")
		return
	end
	if LocalPlayer.state.trashJob then
		TriggerEvent("e_garbageJob:client:notify", "You already have job...", "error")
		return
	end
	LocalPlayer.state:set('trashJob', true, false)
	TriggerServerEvent("e_groups:server:TriggerGroupEvent", nil, "e_garbageJob:client:notify",
		"Get to vehicle and go to gps marked on map!", 'inform')
	TriggerServerEvent("e_garbageJob:server:startJob")
end

local point = lib.points.new({
	coords = npc.coords,
	distance = npc.renderDistance,
})

function point:onEnter()
	lib.requestModel(npc.model, 1000)
	self.ped = CreatePed(0, npc.model, npc.coords, false, false)
	SetModelAsNoLongerNeeded(npc.model)
	SetEntityInvincible(self.ped, true)
	FreezeEntityPosition(self.ped, true)
	SetBlockingOfNonTemporaryEvents(self.ped, true)
	exports.ox_target:addLocalEntity(self.ped, {
		label = "Talk to",
		onSelect = function()
			lib.showContext('trash_npc_menu')
		end
	})
end

function point:onExit()
	if DoesEntityExist(self.ped) then
		DeleteEntity(self.ped)
	end
end

CreateThread(function()
	lib.registerContext({
		id = 'trash_npc_menu',
		title = 'Garbage job',
		options = {
			{
				title = 'Garbage',
				description = 'Start job.',
				icon = 'circle',
				onSelect = function()
					startJob()
				end,
			},
		}
	})
end)
