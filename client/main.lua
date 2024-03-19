local garbageBag = nil
local blip = nil

RegisterNetEvent("e_groups:client:EndJob", function()
	local sleep = 1000
	while true do
		local distance = #(GetEntityCoords(cache.ped) - Config.endCoords.xyz)
		if distance < 10 then
			local isOpen, text = lib.isTextUIOpen()
			if not isOpen then
				lib.showTextUI('[E] - Hide Vehicle')
			end
			if IsControlJustReleased(0, 38) then
				local result = lib.callback.await("e_garbageJob:server:clearRoute", false)
				if result == "success" then
					lib.hideTextUI()
					if blip then
						RemoveBlip(blip)
					end
					LocalPlayer.state:set('trashJob', false, false)
					break
				end
			end
			sleep = 0
		else
			local isOpen, text = lib.isTextUIOpen()
			if isOpen then
				lib.hideTextUI()
			end
			sleep = 1000
		end
		Wait(sleep)
	end
end)
RegisterNetEvent("e_groups:client:syncEndJobBlips", function()
	if blip then
		RemoveBlip(blip)
	end
	blip = CreateBlip(Config.endCoords, 357, 1.0, 69, "#Garbage - End Job")
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 69)
end)

RegisterNetEvent("e_garbageJob:client:SyncNewLocation", function(coords, source, binNetId)
	if blip then
		RemoveBlip(blip)
	end
	blip = CreateBlip(coords, 318, 1.2, 57, "#Garbage - Trash Bin")
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 57)
	if NetworkDoesNetworkIdExist(binNetId) then
		print("Bin already exist's in player's scope!")
		print("Adding Target!")
		addBinTarget(binNetId)
	else
		BinHandler = BinStateBagHandler(source)
	end
end)

lib.callback.register('e_garbageJob:client:doesOwnerWantToContinueJob', function(radius)
	local alert = lib.alertDialog({
		header = 'Garbage job',
		content = 'Do you want to continue your Job and EARN more?',
		centered = true,
		cancel = true,
		labels = {
			cancel = "No",
			confirm = "Yes"
		}
	})
	return alert
end)

RegisterNetEvent("e_garbageJob:client:removeTargetForBin", function(binNetId)
	print("Removing bin target for group")
	exports.ox_target:removeEntity(binNetId)
end)

local function holdingTrashBagAnim()
	local ped = cache.ped
	local bone = GetPedBoneIndex(cache.ped, 28422)

	lib.requestAnimDict("missfbi4prepp1")
	lib.requestModel("prop_cs_street_binbag_01")

	if garbageBag then
		DeleteObject(garbageBag)
		garbageBag = nil
	end

	local bagNetID = lib.callback.await('e_garbageJob:server:getBag', false)
	garbageBag = lib.waitFor(function()
		if NetworkDoesNetworkIdExist(bagNetID) then
			return NetToObj(bagNetID)
		end
	end, 2500)
	ClearPedTasksImmediately(ped)
	SetEntityCollision(garbageBag, false, false)
	AttachEntityToEntity(garbageBag, ped, bone, 0, 0.04, -0.02, 0, 0, 0, true, true, false, true, 1, true)
	Wait(0)
	TaskPlayAnim(ped, "missfbi4prepp1", "_idle_garbage_man", 2.0, 2.0, -1, 51, 1, false, false, false)
end

local function throwGarbageAnim(vehNetId)
	local ped = cache.ped
	local vehicle = NetToVeh(vehNetId)
	SetVehicleDoorOpen(vehicle, 5, false, true)
	ClearPedTasks(ped)
	lib.requestAnimDict('anim@heists@narcotics@trash')
	TaskPlayAnim(ped, 'anim@heists@narcotics@trash', 'throw_b', 1.0, -1.0, -1, 2, 0, false, false, false)
	if garbageBag then
		DeleteObject(garbageBag)
	end
	Wait(1000)
	ClearPedTasks(ped)
	Wait(2000)
	SetVehicleDoorShut(vehicle, 5, false)
end

function addBinTarget(netId)
	exports.ox_target:addEntity(netId, {
		label = "Pick up Bag",
		distance = 2,
		onSelect = function()
			TriggerServerEvent("e_garbageJob:server:PickUpTrashBag")
			holdingTrashBagAnim()
		end,
		canInteract = function(entity)
			return not LocalPlayer.state.isCarryingBag
		end
	})
end

function BinStateBagHandler(groupOwnerId)
	return AddStateBagChangeHandler("trashBin", nil, function(bagName, key, value)
		print("Bin appeared in scope with value: " .. value)
		if value == groupOwnerId then
			-- We wait until NetID exist in player's scope! important
			-- local netId = ObjToNet(GetEntityFromStateBagName(bagName))
			local netId = lib.waitFor(function()
				if NetworkDoesNetworkIdExist(ObjToNet(GetEntityFromStateBagName(bagName))) then
					return ObjToNet(GetEntityFromStateBagName(bagName))
				end
			end, 2500)
			print(("Setting target for bin with netId: %s"):format(netId))
			addBinTarget(netId)
			-- Remove handler after we set target for our object.
			if BinHandler ~= nil then
				print("Cleaning up handler")
				RemoveStateBagChangeHandler(BinHandler)
				BinHandler = nil
			end
		end
	end)
end

RegisterNetEvent("e_garbageJob:client:SetTargetForEntities", function(vehNetId, binNetId, randomRoute, groupOwnerId)
	blip = CreateBlip(randomRoute, 318, 1.2, 57, "#Garbage - Trash Bin")
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 57)
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 57)
	lib.waitFor(function()
		if NetworkDoesNetworkIdExist(vehNetId) then return 1 end
	end, 1500)
	print("auto auto auto", vehNetId, NetworkDoesNetworkIdExist(vehNetId))
	exports.ox_target:addEntity(vehNetId, {
		label = "Throw Bag",
		bones = "boot",
		distance = 2,
		onSelect = function()
			TriggerServerEvent("e_garbageJob:server:throwGarbageToTruck")
			throwGarbageAnim(vehNetId)
		end,
		canInteract = function()
			return LocalPlayer.state.isCarryingBag and LocalPlayer.state.canThrowBag
		end
	})
	if NetworkDoesNetworkIdExist(binNetId) then
		print("Bin already exist's in player's scope!")
		print("Adding Target!")
		addBinTarget(binNetId)
	else
		BinHandler = BinStateBagHandler(groupOwnerId)
	end
end)

RegisterNetEvent("e_garbageJob:client:notify", function(desc, type)
	lib.notify({
		title = 'Garbage job',
		description = desc,
		type = type,
		icon = "square",
		iconAnimation = "spin",
		duration = 5000
	})
end)

function CreateBlip(coords, sprite, scale, colour, text)
	local createdblip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(createdblip, sprite or 1)
	SetBlipScale(createdblip, scale or 1.0)
	SetBlipColour(createdblip, colour or 55)
	SetBlipAsShortRange(createdblip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(text or "NameNotSpecified-e_garbageJob")
	EndTextCommandSetBlipName(createdblip)
	return createdblip
end

CreateThread(function()
	CreateBlip(Config.npc.coords, 318, 1.4, 69, "Garbage Job")
end)
