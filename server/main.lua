local ESX = exports["es_extended"]:getSharedObject()

local Routes = {}

RegisterNetEvent("e_garbageJob:server:startJob", function()
	local src = source
	-- Create Vehicle and wait for it to exist before taking netID
	local vehCreated = CreateVehicleServerSetter(joaat(Config.truck.model), "automobile", Config.truck.coords)
	while not DoesEntityExist(vehCreated) do Wait(10) end

	local randomRoute = Config.Routes[math.random(#Config.Routes)]
	local randomBin = Config.models.bins[math.random(#Config.models.bins)]

	-- Create Bin object and wait for it to exist before taking netID
	local obj = CreateObjectNoOffset(randomBin, randomRoute, true, true, false)
	while not DoesEntityExist(obj) do Wait(10) end

	FreezeEntityPosition(obj, true)
	-- Set trash bin statebag to listen on client
	Entity(obj).state.trashBin = src
	local groupPlayerCount = #exports['e_groups']:getGroupPlayers(src)
	local randomTotalBags = math.random(Config.bags.min, Config.bags.max) * groupPlayerCount
	Routes[src] = {
		vehicleNetworkId = NetworkGetNetworkIdFromEntity(vehCreated),
		binNetworkId = NetworkGetNetworkIdFromEntity(obj),
		courses = 0,           -- how many courses you did / it will be important when it comes to final payment!
		totalBags = randomTotalBags, -- total bags you have to carry to truck
		takenBags = 0,         -- bags taken from bin
		deliveredBags = 0,     -- bags delivered to truck
		cachedCoords = randomRoute
	}
	local route = Routes[src]
	exports['e_groups']:setGroupLockedStatus(src, true)
	TriggerEvent("e_groups:server:TriggerGroupEvent", src, "e_garbageJob:client:SetTargetForEntities",
		route.vehicleNetworkId, route.binNetworkId,
		randomRoute, src)
end)


RegisterNetEvent("e_garbageJob:server:PickUpTrashBag", function()
	local src = source
	-- prevent player from picking up more than one bag
	local groupOwnerId = exports['e_groups']:getGroupOwner(src)
	-- if received -1 means that there is no owner
	if groupOwnerId == -1 then return end
	local route = Routes[groupOwnerId]
	local binNetworkId = route.binNetworkId
	route.takenBags += 1
	if route.takenBags == route.totalBags then
		TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_garbageJob:client:removeTargetForBin",
			binNetworkId)
		TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_garbageJob:client:notify",
			"There is no more bags left in bin!", 'inform')
	end
	Player(src).state:set('isCarryingBag', true, true)
	Player(src).state:set('canThrowBag', true, true)
end)

RegisterNetEvent("e_garbageJob:server:throwGarbageToTruck", function()
	local src = source
	if not Player(src).state.canThrowBag then return end
	local groupOwnerId = exports['e_groups']:getGroupOwner(src)
	if groupOwnerId == -1 then return end
	Player(src).state:set('isCarryingBag', false, true)
	Player(src).state:set('canThrowBag', false, true)
	local route = Routes[groupOwnerId]

	local ped = GetPlayerPed(src)
	local playerCoords = GetEntityCoords(ped)
	local vehicleCoords = GetEntityCoords(NetworkGetEntityFromNetworkId(route.vehicleNetworkId))
	local distance = #(playerCoords - vehicleCoords)
	if distance > 10 then return end

	route.deliveredBags += 1

	if route.deliveredBags == route.totalBags then
		route.courses += 1
		DeleteBin(route.binNetworkId)
		if route.courses < Config.maxCourses then
			local result = lib.callback.await('e_garbageJob:client:doesOwnerWantToContinueJob', groupOwnerId)
			if result == "confirm" then
				route.deliveredBags = 0
				route.takenBags = 0
				local coords = GenerateNewLocation(groupOwnerId)
				TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_garbageJob:client:notify",
					"Group owner decided to do one more course! Go to new location!", 'inform')
				TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_garbageJob:client:SyncNewLocation",
					coords, groupOwnerId, route.binNetworkId)
			else
				TriggerClientEvent("e_groups:client:EndJob", groupOwnerId)
				TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_groups:client:syncEndJobBlips")
				TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_garbageJob:client:notify",
					"Your job has ended! Go back to base to get money.", 'inform')
			end
		elseif route.courses == Config.maxCourses then
			TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_groups:client:syncEndJobBlips")
			TriggerClientEvent("e_groups:client:EndJob", groupOwnerId)
			TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_garbageJob:client:notify",
				"Your job has ended! Go back to base to get money.", 'inform')
		end
	else
		TriggerEvent("e_groups:server:TriggerGroupEvent", groupOwnerId, "e_garbageJob:client:notify",
			("You have %s bags left!"):format(route.totalBags - route.deliveredBags), 'inform')
	end
	Wait(2000)
	Player(src).state:set('canThrowBag', true, true)
end)

function DeleteBin(netID)
	CreateThread(function()
		local bin = NetworkGetEntityFromNetworkId(netID)
		Wait(5000)
		DeleteEntity(bin)
	end)
end

function GenerateNewLocation(groupOwnerId)
	local randomRoute = Config.Routes[math.random(#Config.Routes)]
	local randomBin = Config.models.bins[math.random(#Config.models.bins)]
	while Routes[groupOwnerId].cachedCoords == randomRoute do
		randomRoute = Config.Routes[math.random(#Config.Routes)]
		Wait(0)
	end

	Routes[groupOwnerId].cachedCoords = randomRoute
	local groupPlayerCount = #exports['e_groups']:getGroupPlayers(groupOwnerId)
	Routes[groupOwnerId].totalBags = math.random(Config.bags.min, Config.bags.max) * groupPlayerCount
	-- Create Bin object and wait for it to exist before taking netID
	local obj = CreateObjectNoOffset(randomBin, randomRoute, true, true, false)
	while not DoesEntityExist(obj) do Wait(10) end

	FreezeEntityPosition(obj, true)
	Entity(obj).state.trashBin = groupOwnerId
	-- Set trash bin statebag to listen on client
	Routes[groupOwnerId].binNetworkId = NetworkGetNetworkIdFromEntity(obj)
	return randomRoute
end

lib.callback.register("e_garbageJob:server:clearRoute", function(source)
	local src = source
	local groupPlayers = exports['e_groups']:getGroupPlayers(source)
	local vehicle = NetworkGetEntityFromNetworkId(Routes[src].vehicleNetworkId)
	for i = 1, #groupPlayers, 1 do
		local player = GetPlayerPed(groupPlayers[i].id)
		local vehiclePedIsIn = GetVehiclePedIsIn(player, false)
		if vehiclePedIsIn ~= vehicle then
			TriggerEvent("e_groups:server:TriggerGroupEvent", src, "e_garbageJob:client:notify",
				"Not everyone is in vehicle!", 'error')
			return "fail"
		end
	end
	DeleteEntity(vehicle)
	local randomPayout = math.random(Config.payout.min, Config.payout.max) * Routes[src].courses
	for i = 1, #groupPlayers, 1 do
		exports.ox_inventory:AddItem(groupPlayers[i].id, 'money', randomPayout)
	end
	exports['e_groups']:setGroupLockedStatus(src, false)
	Routes[src] = nil
	return "success"
end)

lib.callback.register('e_garbageJob:server:getBag', function(source)
	local groupOwnerId = exports['e_groups']:getGroupOwner(source)
	if groupOwnerId == -1 then return end
	local ped = GetPlayerPed(source)
	local playerCoords = GetEntityCoords(ped)
	local bag = CreateObjectNoOffset(joaat("prop_cs_street_binbag_01"), playerCoords.x, playerCoords.y, playerCoords.z -
		5, true, true, false)
	while not DoesEntityExist(bag) do
		Wait(10)
	end
	return NetworkGetNetworkIdFromEntity(bag)
end)
