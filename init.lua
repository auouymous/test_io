test_io = {}

local function set_infotext(meta, value)
	meta:set_string("infotext", "Transfer: "..value.."   (right-click to change)")
end

minetest.register_node("test_io:item", {
	description = "Test-IO Item",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -- {x1, y1, z1, x2, y2, z2}
			{-0.5, 0.167, -0.5, 0.5, 0.5, 0.5},				-- top
			{-0.333, -0.167, -0.333, 0.333, 0.167, 0.333},	-- middle
			{-0.167, -0.5, -0.167, 0.167, -0.167, 0.167}	-- bottom
		}
	},
	tiles = {"default_stone.png"},
	paramtype = "light", -- entities inside the node are black without this
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = {cracky = 1, oddly_breakable_by_hand = 1},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			meta:set_int("n", 0)
			set_infotext(meta, 0)
		end
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			local n = meta:get_int("n")
			if n == 99 then n = 0 elseif n == 0 then n = 1 elseif n == 1 then n = 33 else n = n + 33 end
			meta:set_int("n", n)
			set_infotext(meta, n)
		end
	end
})

minetest.register_node("test_io:liquid", {
	description = "Test-IO Liquid",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -- {x1, y1, z1, x2, y2, z2}
			{-0.5, 0.167, -0.5, 0.5, 0.5, 0.5},				-- top
			{-0.333, -0.167, -0.333, 0.333, 0.167, 0.333},	-- middle
			{-0.167, -0.5, -0.167, 0.167, -0.167, 0.167}	-- bottom
		}
	},
	tiles = {
		{
			name = "default_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
	},
	paramtype = "light", -- entities inside the node are black without this
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = {cracky = 1, oddly_breakable_by_hand = 1},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			meta:set_int("mb", 0)
			set_infotext(meta, "0mB")
		end
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			local mb = meta:get_int("mb")
			if mb == 1000 then mb = 0 else mb = mb + 250 end
			meta:set_int("mb", mb)
			set_infotext(meta, mb.."mB")
		end
	end
})

minetest.register_abm({
	label = "TEST-IO transfer",
	nodenames = {"test_io:item", "test_io:liquid"},
	interval = 1.0,
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local take_pos = {x=pos.x, y=pos.y+1, z=pos.z}
		local put_pos = {x=pos.x, y=pos.y-1, z=pos.z}
		local take_node = minetest.get_node(take_pos)
		local put_node = minetest.get_node(put_pos)

		if node.name == "test_io:item" then
			local meta = minetest.get_meta(pos)
			if not meta then return end
			local n = meta:get_int("n")
			if n == 0 then return end

			if node_io.can_take_item(take_pos, take_node, "D") and node_io.can_put_item(put_pos, put_node, "U") == 1 then
				for i = 1, node_io.get_item_size(take_pos, take_node, "D") do
					local stack = node_io.get_item_stack(take_pos, take_node, "D", i)
					if stack then
						local room = node_io.can_put_item(put_pos, put_node, "U", stack, n)
						if room > 0 then
							local itemstack = node_io.take_item(take_pos, take_node, "D", pos, stack, room)
							if itemstack then
								local leftovers = node_io.put_item(put_pos, put_node, "U", pos, itemstack)
								if not leftovers:is_empty() then
									minetest.log("warning", "lost "..leftovers:get_count().." "..leftovers:get_name().." in test-IO item transfer node at "..minetest.pos_to_string(pos))
								end
								break
							end
						end
					end
				end
			end
		else
			local meta = minetest.get_meta(pos)
			if not meta then return end
			local mb = meta:get_int("mb")
			if mb == 0 then return end

			if node_io.can_take_liquid(take_pos, take_node, "D") and node_io.can_put_liquid(put_pos, put_node, "U") == 1
			and (mb >= 1000 or (node_io.accepts_millibuckets(take_pos, take_node, "D") and node_io.accepts_millibuckets(put_pos, put_node, "U")))
			then
				for i = 1, node_io.get_liquid_size(take_pos, take_node, "D") do
					local item = node_io.get_liquid_name(take_pos, take_node, "D", i)
					if item ~= "" then
						local room_mb = node_io.can_put_liquid(put_pos, put_node, "U", item, mb)
						if room_mb > 0 then
							local liquidstack = node_io.take_liquid(take_pos, take_node, "D", pos, item, room_mb)
							if liquidstack then
								local leftover_mb = node_io.put_liquid(put_pos, put_node, "U", pos, liquidstack.name, liquidstack.millibuckets)
								if leftover_mb > 0 then
									minetest.log("warning", "lost "..leftover_mb.."mB "..liquidstack.name.." in test-IO liquid transfer node at "..minetest.pos_to_string(pos))
								end
								break
							end
						end
					end
				end
			end
		end
	end
})
