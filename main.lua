local speechConfig = {
    idleCheckInterval = 1,
    greetingCheckInterval = 1,
    greetingRange = 200,
    chances = {
        attack = 0.2,
        hit = 0.2
    },
    cooldowns = {
        combat = 10,
        idle = {
            minimum = 3,
            scaling = 45
        },
        greeting = {
            minimum = 10,
            scaling = 90
        },
        death = {
            minimum = 1,
            scaling = 0,
        },
        attack = {
            minimum = 3,
            scaling = 25
        },
        hit = {
            minimum = 3,
            scaling = 25
        }
    },
    randomCooldownCoefficient = 2
}

local speechActors = {
    ["yagrum bagarn"] = {
        greeting = {
            {
                path = "Vo\\Misc\\Yagrum_1.mp3",
                duration = 9
            }
        },
        idle = {
            {
                path = "Vo\\Misc\\Yagrum_3.mp3",
                duration = 12
            }
        },
        death = {
            {
                path = "Vo\\Misc\\Yagrum_2.mp3",
                duration = 3
            }
        }
    },
    ["vivec_god"] = {
        greeting = {
            {
                path = "Vo\\Misc\\viv_hlo1.mp3",
                duration = 6
            }
        },
        idle = {
            {
                path = "Vo\\Misc\\viv_idl1.mp3",
                duration = 3
            }
        },
        attack = {
            {
                path = "Vo\\Misc\\viv_atk1.mp3",
                duration = 2
            },
            {
                path = "Vo\\Misc\\viv_atk2.mp3",
                duration = 4
            }
        },
        hit = {
            {
                path = "Vo\\Misc\\viv_alm1.mp3",
                duration = 2
            }
        }
    },
    ["ascended_sleeper"] = {
        attack = {
            {
                path = "Cr\\ascslp\\roar.wav",
                duration = 2
            }
        },
        hit = {
            {
                path = "Cr\\ascslp\\moan.wav",
                duration = 2
            }
        }
    },
    ["slaughterfish"] = {
        attack = {
            {
                path = "Cr\\slfish\\roar.wav",
                duration = 2
            }
        },
        hit = {
            {
                path = "Cr\\slfish\\moan.wav",
                duration = 2
            }
        },
        death = {
            {
                path = "Cr\\slfish\\scrm.wav",
                duration = 3
            }
        }
    },
    ["ash"] = {
        attack = {
            {
                path = "Vo\\Misc\\dagoth_001.mp3",
                duration = 3
            },
            {
                path = "Vo\\Misc\\dagoth_002.mp3",
                duration = 3
            },
            {
                path = "Vo\\Misc\\dagoth_003.mp3",
                duration = 5
            }
        }
    },
    ["dagoth_ur_2"] = {
        idle = {
            {
                path = "Vo\\Misc\\Hit_DU004.mp3",
                duration = 11
            },
        },
        attack = {
            {
                path = "Vo\\Misc\\Hit_DU002.mp3",
                duration = 7
            },
            {
                path = "Vo\\Misc\\Hit_DU005.mp3",
                duration = 6
            },
            {
                path = "Vo\\Misc\\Hit_DU009.mp3",
                duration = 4
            },
            {
                path = "Vo\\Misc\\Hit_DU007.mp3",
                duration = 3
            },
            {
                path = "Vo\\Misc\\Hit_DU010.mp3",
                duration = 3
            },
            {
                path = "Vo\\Misc\\Hit_DU011.mp3",
                duration = 2
            },
            {
                path = "Vo\\Misc\\Hit_DU012.mp3",
                duration = 2
            },
        },
        hit = {
            {
                path = "Vo\\Misc\\Hit_DU001.mp3",
                duration = 6
            },
            {
                path = "Vo\\Misc\\Hit_DU003.mp3",
                duration = 6
            },
            {
                path = "Vo\\Misc\\Hit_DU006.mp3",
                duration = 3
            },
            {
                path = "Vo\\Misc\\Hit_DU008.mp3",
                duration = 2
            },
            {
                path = "Vo\\Misc\\Hit_DU013.mp3",
                duration = 2
            },
            {
                path = "Vo\\Misc\\Hit_DU014.mp3",
                duration = 2
            }
        }
    }
}

local alias = {
    ["slaughterfish"] = {
        "slaughterfish_hr_sfavd",
        "slaughterfish_small"
    },
    ["ash"] = {
        "ash_ghoul",
        "ash_ghoul_fgr",
        "ash_ghoul_ganel",
        "ash_ghoul_mulyn",
        "ash_slave",
        "ash_zombie",
        "ash_zombie_fgaz",
        "corprus_lame",
        "corprus_lame_fyr01",
        "corprus_lame_fyr02",
        "corprus_lame_fyr03",
        "corprus_lame_fyr04",
        "corprus_lame_morvayn",
        "corprus_stalker",
        "corprus_stalker_berwen",
        "corprus_stalker_danar",
        "corprus_stalker_fgcs",
        "corprus_stalker_fyr01",
        "corprus_stalker_fyr02",
        "corprus_stalker_fyr03",
        "corprus_stalker_morvayn"
    }
}

for old, list in pairs(alias) do
    for _, new in pairs(list) do
        speechActors[new] = speechActors[old]
    end
end

local IDLE = "idle"
local GREETING = "greeting"
local DEATH = "death"
local ATTACK = "attack"
local HIT = "hit"

local loadedActors = {
    [IDLE] = {},
    [GREETING] = {}
}
local combatActors = {}
local cooldowns = {}
local speaking = {}

local function hasSpeech(refId, speechType)
    return speechActors[refId] and (
        not speechType or speechActors[refId][speechType]
    )
end

local function inCombat(uniqueIndex)
    local threshold = tes3mp.GetMillisecondsSinceServerStart() - time.seconds(speechConfig.cooldowns.combat)
    local result = combatActors[uniqueIndex] and combatActors[uniqueIndex] <= threshold
    if not result then
        combatActors[uniqueIndex] = nil
    end
    return result
end

local function checkCooldown(uniqueIndex, speechType)
    if speaking[uniqueIndex] then return false end
    return not cooldowns[uniqueIndex] or
        (
            not cooldowns[uniqueIndex][speechType]
            and (
                not speechConfig.chances[speechType]
                or math.random() < speechConfig.chances[speechType]
            )
        ) or
        (
            cooldowns[uniqueIndex][speechType]
            and cooldowns[uniqueIndex][speechType] < tes3mp.GetMillisecondsSinceServerStart()
        )
end

local function updateCooldown(uniqueIndex, speechType, interval)
    if not cooldowns[uniqueIndex] then
        cooldowns[uniqueIndex] = {}
    end
    cooldowns[uniqueIndex][speechType] = interval + tes3mp.GetMillisecondsSinceServerStart()
end

local function calculateCooldown(refId, speechType)
    local list = speechActors[refId][speechType]
    return (1 + (speechConfig.randomCooldownCoefficient - 1) *
        math.random()) *
        time.seconds(
            speechConfig.cooldowns[speechType].minimum +
            speechConfig.cooldowns[speechType].scaling * (0.25 + -1.5 / (-1 - #list))
        )
end

local function chooseSpeech(refId, speechType)
    local list = speechActors[refId][speechType]
    local index = math.random(1, #list)
    return list[index]
end

local function sendSpeech(speech, cellDescription, uniqueIndex)--, onlyThisCell, exclude)
    local cell = LoadedCells[cellDescription]
    if not cell then return end
    for _, pid in pairs(cell.visitors) do
        if Players[pid] and Players[pid]:IsLoggedIn()  then
            logicHandler.RunConsoleCommandOnObject(
                pid,
                string.format(
                    'Say "%s", "%s"',
                    speech.path,
                    speech.subtitle or ""
                ),
                cellDescription,
                uniqueIndex,
                false
            )
        end
    end
    --[[if not onlyThisCell and cell.isExterior then
        for dx = -1, 1 do
            for dy = -1, 1 do
                local neighbourDescription = string.format(
                    "%d, %d",
                    cell.gridX + dx,
                    cell.gridY + dy
                )
                playSpeech(path, neighbourDescription, uniqueIndex, true)
            end
        end
    end]]
end

local function playSpeech(refId, speechType, cellDescription, uniqueIndex)
    local delay = calculateCooldown(refId, speechType)
    updateCooldown(uniqueIndex, speechType, delay)
    local speech = chooseSpeech(refId, speechType)
    sendSpeech(speech, cellDescription, uniqueIndex)
    speaking[uniqueIndex] = true
    timers.Timeout(time.seconds(speech.duration or 1), function()
        speaking[uniqueIndex] = false
    end)
end

-- combat status

customEventHooks.registerHandler("OnObjectHit", function(eventStatus, pid, cellDescription, objects, players)
    if not eventStatus.validCustomHandlers then return end
    for _, player in pairs(players) do
        local refId = player.hittingRefId
        local uniqueIndex = player.hittingUniqueIndex
        if refId and uniqueIndex and hasSpeech(refId) then
            combatActors[uniqueIndex] = tes3mp.GetMillisecondsSinceServerStart()
        end
    end
    for uniqueIndex, object in pairs(objects) do
        local refId = object.hittingRefId
        if refId and hasSpeech(refId) then
            combatActors[uniqueIndex] = tes3mp.GetMillisecondsSinceServerStart()
        end
    end
end)

-- keep track of loaded actors

local loadedActorsTypes = { IDLE, GREETING }
local function addLoadedActor(uniqueIndex, refId, cellDescription)
    for _, speechType in pairs(loadedActorsTypes) do
        local loadedForType = loadedActors[speechType]
        if hasSpeech(refId, speechType) and not loadedForType[uniqueIndex] then
            loadedForType[uniqueIndex] = {
                refId = refId,
                cellDescription = cellDescription
            }
        end
    end
    if hasSpeech(refId, IDLE) and not cooldowns[uniqueIndex] then
        updateCooldown(uniqueIndex, IDLE, calculateCooldown(refId, IDLE))
    end
end

local function updateLoadedActor(uniqueIndex, cellDescription)
    for _, speechType in pairs(loadedActorsTypes) do
        local loadedForType = loadedActors[speechType]
        if loadedForType[uniqueIndex] then
            loadedForType[uniqueIndex].cellDescription = cellDescription
        end
    end
end

local function removeLoadedActor(uniqueIndex)
    for _, speechType in pairs(loadedActorsTypes) do
        local loadedForType = loadedActors[speechType]
        loadedForType[uniqueIndex] = nil
    end
end

customEventHooks.registerHandler("OnActorList", function(eventStatus, pid, cellDescription, actors)
    for _, actor in pairs(actors) do
        if actor.uniqueIndex and actor.refId then
            addLoadedActor(actor.uniqueIndex, actor.refId, cellDescription)
        end
    end
end)

customEventHooks.registerHandler("OnCellLoad", function(eventStatus, pid, cellDescription)
    local cell = LoadedCells[cellDescription]
    for _, uniqueIndex in pairs(cell.data.packets.actorList) do
        local actor = cell.data.objectData[uniqueIndex]
        if actor.refId and not actor.deathState then
            addLoadedActor(uniqueIndex, actor.refId, cellDescription)
        end
    end
end)

customEventHooks.registerHandler("OnCellUnload", function(eventStatus, pid, cellDescription)
    local cell = LoadedCells[cellDescription]
    for _, uniqueIndex in pairs(cell.data.packets.actorList) do
        removeLoadedActor(uniqueIndex)
    end
end)

customEventHooks.registerHandler("OnActorDeath", function(eventStatus, pid, cellDescription, actors)
    if not eventStatus.validCustomHandlers then return end
    for _, actor in pairs(actors) do
        if actor.deathState then
            removeLoadedActor(actor.uniqueIndex)
        end
    end
end)

customEventHooks.registerHandler("OnActorCellChange", function(eventStatus, pid, cellDescription, actors)
    if not eventStatus.validCustomHandlers then return end
    for _, actor in pairs(actors) do
        updateLoadedActor(actor.uniqueIndex, actor.cellDescription)
    end
end)

-- IDLE

timers.Interval(time.seconds(speechConfig.idleCheckInterval), function()
    for uniqueIndex, actor in pairs(loadedActors[IDLE]) do
        if not inCombat(uniqueIndex) and checkCooldown(uniqueIndex, IDLE) then
            playSpeech(actor.refId, IDLE, actor.cellDescription, uniqueIndex)
        end
    end
end)

-- GREETING

local axes = { "posX", "posY", "posZ" }
local function distance(loc1, loc2)
    local result = 0
    for _, axis in pairs(axes) do
        local delta = loc1[axis] - loc2[axis]
        result = result + delta * delta
    end
    return math.sqrt(result)
end

local function withinGreetingRange(uniqueIndex, cellDescription)
    if not LoadedCells[cellDescription] then return false end
    local objData = LoadedCells[cellDescription].data.objectData
    if not objData[uniqueIndex] then return false end
    local actorLocation = objData[uniqueIndex].location
    if not actorLocation then return end
    for _, pid in pairs(LoadedCells[cellDescription].visitors) do
        Players[pid]:SaveCell()
        local playerLocation = Players[pid].data.location
        local distance = distance(playerLocation, actorLocation)
        tes3mp.LogMessage(enumerations.log.INFO, "[Speech] DISTANCE: " .. pid .. " " .. distance)
        if distance < speechConfig.greetingRange then
            return true
        end
    end
    return false
end

timers.Interval(time.seconds(speechConfig.greetingCheckInterval), function()
    for uniqueIndex, actor in pairs(loadedActors[GREETING]) do
        if not inCombat(uniqueIndex) and
            checkCooldown(uniqueIndex, GREETING) and
            withinGreetingRange(uniqueIndex, actor.cellDescription)
        then
            playSpeech(actor.refId, GREETING, actor.cellDescription, uniqueIndex)
        end
    end
end)

-- DEATH

customEventHooks.registerHandler("OnActorDeath", function(eventStatus, pid, cellDescription, actors)
    if not eventStatus.validCustomHandlers then return end
    local objectData = LoadedCells[cellDescription].data.objectData
    for _, actor in pairs(actors) do
        local uniqueIndex = actor.uniqueIndex
        local object = objectData[uniqueIndex]
        if object and object.refId and
            hasSpeech(object.refId, DEATH) and checkCooldown(uniqueIndex, DEATH)
        then
            playSpeech(object.refId, DEATH, cellDescription, uniqueIndex)
        end
    end
end)

-- ATTACK

customEventHooks.registerHandler("OnObjectHit", function(eventStatus, pid, cellDescription, objects, players)
    if not eventStatus.validCustomHandlers then return end
    for _, player in pairs(players) do
        local refId = player.hittingRefId
        local uniqueIndex = player.hittingUniqueIndex
        if refId and uniqueIndex and hasSpeech(refId, ATTACK) and checkCooldown(uniqueIndex, ATTACK) then
            playSpeech(refId, ATTACK, cellDescription, uniqueIndex)
        end
    end
    for uniqueIndex, object in pairs(objects) do
        local refId = object.hittingRefId
        if refId and hasSpeech(refId, ATTACK) and checkCooldown(uniqueIndex, ATTACK) then
            playSpeech(refId, ATTACK, cellDescription, uniqueIndex)
        end
    end
end)

-- HIT

customEventHooks.registerHandler("OnObjectHit", function(eventStatus, pid, cellDescription, objects, players)
    if not eventStatus.validCustomHandlers then return end
    for uniqueIndex, object in pairs(objects) do
        local refId = object.refId
        if refId and hasSpeech(refId, HIT) and checkCooldown(uniqueIndex, HIT) then
            playSpeech(refId, HIT, cellDescription, uniqueIndex)
        end
    end
end)
