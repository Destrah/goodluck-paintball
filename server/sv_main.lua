local QBCore = exports['qb-core']:GetCoreObject()
local currentRuns = {} --Identifier = isCurrentlyBrewing, amountBrewing, amountDelivering, name, truckId
Citizen.CreateThread(function()
	while QBCore == nil do
		QBCore = exports['qb-core']:GetCoreObject()
        Citizen.Wait(10)
	end
end)

local games = {}
local activeGame = false
local activeGameId = -1
local gameStarted = false
local givingRewards = 0

function startGameCheck()
	Citizen.CreateThread(function()
		while activeGame do
			local gameinfo = games[activeGameId]
			if gameStarted then
				if (os.time() - gameinfo.starttime) > (180 * gameinfo.lives) then
					for playerid, info in pairs(gameinfo.currentplayers) do
						TriggerClientEvent('paintball-client:endGame', playerid, info.lives, 0, 0, 'None')
						TriggerClientEvent('QBCore:Notify', playerid, 'Game ended due to taking too long', 999)
					end
					activeGame = false
					activeGameId = -1
					gameStarted = false
					games = {}
				end
				for playerid, info in pairs(gameinfo.currentplayers) do
					local ped = GetPlayerPed(playerid)
					if ped == nil or ped == 0 then
						for playersource, playerinfo in pairs(gameinfo.currentplayers) do
							TriggerClientEvent('paintball-client:endGame', playersource, playerinfo.lives, 0, 0, 'None')
							TriggerClientEvent('QBCore:Notify', playersource, 'Game ended due to someone\'s head popping', 999)
						end
						activeGame = false
						activeGameId = -1
						gameStarted = false
						games = {}
						break
					end
				end
			else
				if (os.time() - gameinfo.createtime) > 200 then
					for playerid, info in pairs(gameinfo.currentplayers) do
						TriggerClientEvent('paintball-client:endGame', playerid, info.lives, 0, 0, 'None')
						TriggerClientEvent('QBCore:Notify', playerid, 'Game was canceled due to start taking too long', 999)
					end
					activeGame = false
					activeGameId = -1
					gameStarted = false
					games = {}
				end
				for playerid, info in pairs(gameinfo.currentplayers) do
					local ped = GetPlayerPed(playerid)
					if ped == nil or ped == 0 then
						for playersource, playerinfo in pairs(gameinfo.currentplayers) do
							TriggerClientEvent('paintball-client:endGame', playersource, playerinfo.lives, 0, 0, 'None')
							TriggerClientEvent('QBCore:Notify', playersource, 'Game ended due to someone\'s head popping', 999)
						end
						activeGame = false
						activeGameId = -1
						gameStarted = false
						games = {}
						break
					end
				end
			end
			Citizen.Wait(1000)
		end
	end)
end

RegisterNetEvent('paintball-server:create')
AddEventHandler('paintball-server:create', function(maxplayers, betamount, lives, ped, passwordString)
	local _source = source
	if not activeGame then
		local currentGame = 1
		for id, data in pairs(games) do
			if currentGame ~= id then
				break
			else
				currentGame = currentGame + 1
			end
		end
		local password = false
		if passwordString ~= nil then
			password = passwordString
		else
			passwordString = ''
		end
		games[currentGame] = {
			maxplayers = maxplayers,
			betamount = betamount,
			lives = lives,
			currentplayers = {},
			playercount = 0,
			redteamcount = 0,
			blueteamcount = 0,
			creator = _source,
			createtime = os.time(),
			password = password
		}
		TriggerClientEvent('chatMessage', _source, 'Paintball game successfully created:\nID: ' .. currentGame .. '\nMax Players: ' .. maxplayers .. '\nBet: ' .. betamount .. '\nLives: ' .. lives)
		TriggerEvent('paintball-server:join', currentGame, ped, passwordString, _source)
		activeGame = true
		activeGameId = currentGame
		startGameCheck()
	else
		TriggerClientEvent('QBCore:Notify', _source, 'There is already a game in progress.', 2)
	end
end)

RegisterNetEvent('paintball-server:join')
AddEventHandler('paintball-server:join', function(id, ped, password, sentSource)
	local _source = source
	if sentSource then
		_source = sentSource
	end
	local xPlayer = QBCore.Functions.GetPlayer(_source)
	local gameinfo = games[id]
	if gameinfo ~= nil then
		if xPlayer.Functions.GetMoney("cash") >= gameinfo.betamount then
			if gameinfo.password then
				if password ~= nil then
					if gameinfo.password == password then
						if gameinfo.maxplayers - gameinfo.playercount > 0 then
							--if gameinfo.maxplayers == 2 then
							if gameinfo.currentplayers[_source] == nil then
								local team = "red"
								if gameinfo.playercount % 2 ~= 0 then
									team = "blue"
								end
								gameinfo.playercount = gameinfo.playercount + 1
								gameinfo.currentplayers[_source] = {team = team, lives = gameinfo.lives, playerped = GetPlayerPed(_source), alive = true}
								xPlayer.Functions.RemoveItem('pticket', 1, false, {}, true)
								TriggerEvent('paintball-server:takeBet', id, _source)
								TriggerClientEvent('chatMessage', gameinfo.creator, gameinfo.playercount .. '/' ..gameinfo.maxplayers .. ' have joined')
							else
								TriggerClientEvent('QBCore:Notify', _source, 'You have already joined this game.', 2)
							end
								--[[if gameinfo.playercount == gameinfo.maxplayers then
									for playerid, info in pairs(gameinfo.currentplayers) do
										TriggerClientEvent('paintball-client:startGame', tonumber(playerid), id)
									end
									activeGame = true
									activeGameId = id
								end--]]
							--else
							--	TriggerClientEvent('QBCore:Notify', _source, 'That game is already full', 2)
							--end
						else
							TriggerClientEvent('QBCore:Notify', _source, 'That game is already full', 2)
						end
					else
						TriggerClientEvent('QBCore:Notify', _source, 'That is not the correct password', 2)
					end
				else
					TriggerClientEvent('QBCore:Notify', _source, 'This match is protected with a password', 2)
				end
			else
				if gameinfo.maxplayers - gameinfo.playercount > 0 then
					--if gameinfo.maxplayers == 2 then
					if gameinfo.currentplayers[_source] == nil then
						local team = "red"
						if gameinfo.playercount % 2 ~= 0 then
							team = "blue"
						end
						gameinfo.playercount = gameinfo.playercount + 1
						gameinfo.currentplayers[_source] = {team = team, lives = gameinfo.lives, playerped = GetPlayerPed(_source), alive = true}
						xPlayer.Functions.RemoveItem('pticket', 1, false, {}, true)
						TriggerEvent('paintball-server:takeBet', id, _source)
						TriggerClientEvent('chatMessage', gameinfo.creator, gameinfo.playercount .. '/' ..gameinfo.maxplayers .. ' have joined')
					else
						TriggerClientEvent('QBCore:Notify', _source, 'You have already joined this game.', 2)
					end
						--[[if gameinfo.playercount == gameinfo.maxplayers then
							for playerid, info in pairs(gameinfo.currentplayers) do
								TriggerClientEvent('paintball-client:startGame', tonumber(playerid), id, info.lives, info.team)
							end
							activeGame = true
							activeGameId = id
						end--]]
					--else
					--	TriggerClientEvent('QBCore:Notify', _source, 'That game is already full', 2)
					--end
				else
					TriggerClientEvent('QBCore:Notify', _source, 'That game is already full', 2)
				end
			end
		else
			TriggerClientEvent('QBCore:Notify', _source, 'You do not have enough cash on hand', 2)
		end
	else
		TriggerClientEvent('QBCore:Notify', _source, 'There does not appear to be a game created with the id of ' .. id, 2)
	end
end)

RegisterNetEvent('paintball-server:startGame')
AddEventHandler('paintball-server:startGame', function(id)
	local _source = source
	local gameinfo = games[id]
	if gameinfo ~= nil then
		if gameinfo.creator == _source then
			for playerid, info in pairs(gameinfo.currentplayers) do
				TriggerClientEvent('paintball-client:startGame', tonumber(playerid), id, info.lives, info.team)
			end
		end
		gameStarted = true
		gameinfo.starttime = os.time()
	end
end)

RegisterNetEvent('paintball-server:startNewRound')
AddEventHandler('paintball-server:startNewRound', function(id)
	local gameinfo = games[id]
	for playerid, info in pairs(gameinfo.currentplayers) do
		info.alive = true
	end
end)

RegisterNetEvent('paintball-server:endGame')
AddEventHandler('paintball-server:endGame', function(id)
	local gameinfo = games[id]
	for playerid, info in pairs(gameinfo.currentplayers) do
		TriggerClientEvent('paintball-client:endGame', playerid)
	end
	activeGame = false
end)

RegisterNetEvent('paintball-server:handleDowned')
AddEventHandler('paintball-server:handleDowned', function(id)
	local _source = source
	local gameinfo = games[id]
	gameinfo.currentplayers[_source].lives = gameinfo.currentplayers[_source].lives - 1
	gameinfo.currentplayers[_source].alive = false
	local hasAliveTeamate = false
	local teamLivesLeft = 0
	local redCount = 0
	local blueCount = 0
	for playerid, info in pairs(gameinfo.currentplayers) do
		if info.team == gameinfo.currentplayers[_source].team and info.alive then
			hasAliveTeamate = true
		end
		if info.team == gameinfo.currentplayers[_source].team then
			teamLivesLeft = teamLivesLeft + info.lives
		end
		if info.team == 'red' then redCount = redCount + 1 end
		if info.team == 'blue' then blueCount = blueCount + 1 end
	end
	if not hasAliveTeamate then
		if teamLivesLeft > 0 then
			for playerid, info in pairs(gameinfo.currentplayers) do
				print(playerid, info)
				TriggerClientEvent('paintball-client:restartRound', playerid, info.lives)
			end
		else
			local winningTeam = 'red'
			if gameinfo.currentplayers[_source].team == 'red' then
				winningTeam = 'blue'
			end
			for playerid, info in pairs(gameinfo.currentplayers) do
				local teamCount = redCount
				if info.team == 'blue' then
					teamCount = blueCount
				end
				if info.team == winningTeam then
					givingRewards = givingRewards + 1
				end
				TriggerClientEvent('paintball-client:endGame', playerid, info.lives, teamCount, (blueCount + redCount), winningTeam)
			end
			while givingRewards > 0 do
				Citizen.Wait(100)
			end
			activeGame = false
			activeGameId = -1
			gameStarted = false
			games = {}
		end
	else
		TriggerClientEvent('QBCore:Notify', _source, 'You have been downed and are waiting for cause you still have teamate alive.', 1)
	end
end)

RegisterNetEvent('paintball-server:giveReward')
AddEventHandler('paintball-server:giveReward', function(id, team, total)
	local _source = source
	local gameinfo = games[id]
	if gameinfo ~= nil then
		local xPlayer = QBCore.Functions.GetPlayer(_source)
		xPlayer.Functions.AddMoney("cash", math.floor((gameinfo.betamount * total) / team))
		xPlayer.Functions.AddItem('pticket', 1, false, {}, true)
		givingRewards = givingRewards - 1
	end
end)

RegisterNetEvent('paintball-server:takeBet')
AddEventHandler('paintball-server:takeBet', function(id, sentSource)
	local _source = source
	if sentSource then
		_source = sentSource
	end
	local gameinfo = games[id]
	local xPlayer = QBCore.Functions.GetPlayer(_source)
	xPlayer.Functions.RemoveMoney("cash", gameinfo.betamount)
end)

function joinGame()
	
end