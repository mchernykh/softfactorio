require "locale/utils/event" 
require "locale/modules/upgradeplanner"


-- Give player starting items.
-- @param event on_player_joined event
function player_joined(event)
	local player = game.players[event.player_index]
	--if game.tick < ticks_from_minutes(10) then
		player.insert { name = "pistol", count = 1 }
		player.insert { name = "firearm-magazine", count = 20 }
		player.insert { name = "burner-mining-drill", count = 2 }
		player.insert { name = "stone-furnace", count = 2 }
	--end

	if (player.force.technologies["steel-processing"].researched) then
        player.insert { name = "steel-axe", count = 2 }
    else
        player.insert { name = "iron-axe", count = 5 }
    end
	
	local belts = {
		"transport-belt",
		"fast-transport-belt",
		"express-transport-belt",
		"underground-belt",
		"fast-underground-belt",
		"express-underground-belt",
		"splitter",
		"fast-splitter",
		"express-splitter"
	}
		
	for _, v in pairs(belts) do
		player.insert { name = v, count = 100 }
	end
	
	player.insert { name = "transport-belt", count = 300 }
	player.insert { name = "fast-transport-belt", count = 300 }
	player.insert { name = "express-transport-belt", count = 300 }
	player.insert { name = "roboport", count = 5 }
	player.insert { name = "logistic-chest-storage", count = 5 }
	player.insert { name = "construction-robot", count = 100 }
	player.insert { name = "solar-panel", count = 150 }
	player.insert { name = "medium-electric-pole", count = 100 }

end

-- Give player weapons after they respawn.
-- @param event on_player_respawned event
function player_respawned(event)
	local player = game.players[event.player_index]

	if (player.force.technologies["military"].researched) then
        player.insert { name = "submachine-gun", count = 1 }
    else
		player.insert { name = "pistol", count = 1 }
    end

	if (player.force.technologies["uranium-ammo"].researched) then
        player.insert { name = "uranium-rounds-magazine", count = 10 }
    else 
		if (player.force.technologies["military-2"].researched) then
			player.insert { name = "piercing-rounds-magazine", count = 10 }
		else
			player.insert { name = "firearm-magazine", count = 10 }
		end
	end
end

Event.register(defines.events.on_player_created, player_joined)
Event.register(defines.events.on_player_respawned, player_respawned)

--Time for the debug code.  If any (not global.) globals are written to at this point, an error will be thrown.
--eg, x = 2 will throw an error because it's not global.x or local x
--function global_debug()
	setmetatable(_G, {
		__newindex = function(_, n)
			log("Attempt to write to undeclared var " .. n)
			game.print("Attempt to write to undeclared var " .. n)
		end
	})
--end

--Event.register(-1, global_debug)