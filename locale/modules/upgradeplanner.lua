--Upgrade planner, intended for use in scenarios.
--Written by mchernykh, 2018
--MIT License

if MODULE_LIST then
	module_list_add("Upgrade planner")
end

function get_planner_type(event, valid_item_types, player)
		local item = player.cursor_stack
		if item == nil then
			return nil
		end
		
		if event.alt then --ignore
			return nil
		end

		if not item.trees_and_rocks_only then
			return nil
		end
		
		local matches = 0
		local best_match = nil
		for _, filter_entity in pairs(item.entity_filters) do		
			for key, __ in pairs(valid_item_types) do
				if key == filter_entity then
					matches = matches + 1
					best_match = key
				end
			end
		end
		if matches > 1 then
			player.print("upgrade planner: use only one yellow/red/blue belt filtering for upgrade planner. the color of filter means desirable color after upgrade")
			return nil
		end
		return best_match
	end
	
--[[
function upgrade_entities_old(player, area, upgrade_from_list, upgrade_to_entity)
	local surface = player.surface
	local force = player.force
	for _, entity_name in pairs(upgrade_from_list) do
		local entities = surface.find_entities_filtered{name=entity_name, area=area, force=player.force}
		player.print("entity_name: "..entity_name.." entity_count: "..#entities)
		for _, entity in pairs(entities) do
			--if entity.name == upgrade_to_entity and entity.to_be_deconstructed(force) then
			--	entity.cancel_deconstruction(force, player)
			--end
			if entity.name ~= upgrade_to_entity then
				entity.order_deconstruction(force, player)
				local new_entity = surface.create_entity({
					name='entity-ghost',
					-- ghost_name = upgrade_to_entity , 
					position = entity.position, 
					direction = entity.direction,
					-- ghost_prototype = game.item_prototypes[upgrade_to_entity].place_result,
					force = force,
					inner_name = upgrade_to_entity,
					--player = player,
					splitter_filter = entity.splitter_filter,
					splitter_input_priority = entity.splitter_input_priority,
					splitter_output_priority = entity.splitter_output_priority})
				-- new_entity.belt_to_ground_type = entity.belt_to_ground_type -- underground belts
				-- new_entity.loader_type = entity.loader_type -- loaders
				--new_entity.splitter_filter = entity.splitter_filter -- splitters
				--new_entity.splitter_input_priority = entity.splitter_input_priority -- splitters
				--new_entity.splitter_output_priority = entity.splitter_output_priority -- splitters
				
			end
		end
	end
	return
end
]]--

function upgrade_entities(player, area, upgrade_from_list, upgrade_to_entity)
	local surface = player.surface
	local force = player.force
	
	-- lets hack and create blueprint in the chest for capturing stuff
	local chest_position = player.surface.find_non_colliding_position('iron-chest', player.position, 100, 1)
	if chest_position == nil then
		player.print("hack can't be done: use upgrade planner later")
		return
	end
	local chest_entity = surface.create_entity({
					name='iron-chest',
					force = force,
					position = chest_position})
					
	chest_entity.insert{name = "blueprint", count = 1}
	local bp_item = chest_entity.get_inventory(defines.inventory.chest).find_item_stack("blueprint")
	
	local regular_entities = {}
	
	for _, entity_name in pairs(upgrade_from_list) do
		local entities = surface.find_entities_filtered{name=entity_name, area=area, force=player.force}
		for i=1, #entities do
			regular_entities[#regular_entities + 1] = entities[i]
		end
	end
	
	for _, entity in pairs(regular_entities) do
		if entity.name ~= upgrade_to_entity then
			local selection_box = entity.selection_box
			local bp_center = {x = (selection_box.right_bottom.x + selection_box.left_top.x) / 2, y = (selection_box.right_bottom.y + selection_box.left_top.y) / 2}
			bp_item.create_blueprint{surface=surface, force=force, area=entity.selection_box, always_include_tiles=false}
			local new_entities = bp_item.get_blueprint_entities()
			new_entities[1].name = upgrade_to_entity
			bp_item.set_blueprint_entities(new_entities)
			entity.order_deconstruction(force, player)
			
			bp_item.build_blueprint{surface=surface, force=force, position = bp_center, force_build = false}
			bp_item.clear_blueprint()			
		end
	end	

	local ghost_entities = surface.find_entities_filtered{name = "entity-ghost", area=area, force=player.force}
	local filtered_ghost_entities = {}
	
	for _, ghost in pairs(ghost_entities) do
		for __, proto in pairs(upgrade_from_list) do
			if ghost.ghost_name == proto and proto ~= upgrade_to_entity then
				filtered_ghost_entities[#filtered_ghost_entities + 1] = ghost
			end
		end
	end
	
	for _, entity in pairs(filtered_ghost_entities) do
		local selection_box = entity.selection_box
		local bp_center = {x = (selection_box.right_bottom.x + selection_box.left_top.x) / 2, y = (selection_box.right_bottom.y + selection_box.left_top.y) / 2}
		bp_item.create_blueprint{surface=surface, force=force, area=entity.selection_box, always_include_tiles=false}
		local new_entities = bp_item.get_blueprint_entities()
		new_entities[1].name = upgrade_to_entity
		bp_item.set_blueprint_entities(new_entities)
		entity.destroy()
			
		bp_item.build_blueprint{surface=surface, force=force, position = bp_center, force_build = false}
		bp_item.clear_blueprint()
	end	
	
	chest_entity.destroy()
	return
end

function upgradeplan(event)

    local player = game.players[event.player_index]
    local force = player.force

	local belts = {
	["transport-belt"] = "transport-belt",
	["fast-transport-belt"] = "fast-transport-belt", 
	["express-transport-belt"] = "express-transport-belt"
	}
	
	local underground_belts = {
	["transport-belt"] = "underground-belt",
	["fast-transport-belt"] = "fast-underground-belt", 
	["express-transport-belt"] = "express-underground-belt"
	}
	
	local splitter_belts = {
	["transport-belt"] = "splitter",
	["fast-transport-belt"] = "fast-splitter", 
	["express-transport-belt"] = "express-splitter"
	}
	
	local loader_belts = {
	["transport-belt"] = "loader",
	["fast-transport-belt"] = "fast-loader", 
	["express-transport-belt"] = "express-loader"
	}
	
	local upgradeplannertype = get_planner_type(event, belts, player)
	if upgradeplannertype == nil then
		return
	end
	
	upgrade_entities(player, event.area, belts, belts[upgradeplannertype])
	upgrade_entities(player, event.area, underground_belts, underground_belts[upgradeplannertype])
	upgrade_entities(player, event.area, splitter_belts, splitter_belts[upgradeplannertype])
	upgrade_entities(player, event.area, loader_belts, loader_belts[upgradeplannertype])
	
	return
end

Event.register(defines.events.on_player_deconstructed_area, upgradeplan)
