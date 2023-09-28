/*
	Screen objects
	Todo: improve/re-implement

	Screen objects are only used for the hud and should not appear anywhere "in-game".
	They are used with the client/screen list and the screen_loc var.
	For more information, see the byond documentation on the screen_loc and screen vars.
*/

/atom/movable/screen
	name = ""
	icon = 'icons/mob/hud/screen1.dmi'
	icon_state = "x"
	plane = HUD_PLANE
	layer = ABOVE_HUD_LAYER
	unacidable = TRUE
	animate_movement = SLIDE_STEPS
	appearance_flags = NO_CLIENT_COLOR //So that saturation/desaturation etc. effects don't hit the HUD.
	vis_flags = VIS_INHERIT_PLANE
	var/obj/master = null	//A reference to the object in the slot. Grabs or items, generally.
	/// A reference to the owner HUD, if any.
	var/datum/hud/hud = null
	/**
	 * Map name assigned to this object.
	 * Automatically set by /client/proc/add_obj_to_map.
	 */
	var/assigned_map
	/**
	 * Mark this object as garbage-collectible after you clean the map
	 * it was registered on.
	 *
	 * This could probably be changed to be a proc, for conditional removal.
	 * But for now, this works.
	 */
	var/del_on_map_removal = TRUE

	/// If FALSE, this will not be cleared when calling /client/clear_screen()
	var/clear_with_screen = TRUE

/atom/movable/screen/proc/update_icon()

/atom/movable/screen/text
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = CINEMATIC_PLANE
	layer = CINEMATIC_LAYER
	maptext_height = 480
	maptext_width = 480
	appearance_flags = NO_CLIENT_COLOR|PIXEL_SCALE

/atom/movable/screen/cinematic
	plane = CINEMATIC_PLANE
	layer = CINEMATIC_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "1,0"

/atom/movable/screen/cinematic/explosion
	icon = 'icons/effects/station_explosion.dmi'
	icon_state = "intro_ship"

/atom/movable/screen/cinematic/ground
	icon = 'icons/effects/station_explosion.dmi'
	icon_state = "intro_planet"

/atom/movable/screen/inventory
	var/slot_id //The indentifier for the slot. It has nothing to do with ID cards.


/atom/movable/screen/close
	name = "close"
	icon_state = "x"


/atom/movable/screen/close/clicked(mob/user)
	if(master)
		if(isstorage(master))
			var/obj/item/storage/master_storage = master
			master_storage.storage_close(user)
	return TRUE


/atom/movable/screen/action_button
	icon = 'icons/mob/hud/actions.dmi'
	icon_state = "template"
	var/datum/action/source_action
	var/image/maptext_overlay

/atom/movable/screen/action_button/attack_ghost(mob/dead/observer/user)
	return FALSE

/atom/movable/screen/action_button/clicked(mob/user)
	if(!user || !source_action)
		return TRUE

	if(source_action.can_use_action())
		source_action.action_activate()
	return TRUE

/atom/movable/screen/action_button/Destroy()
	source_action = null
	QDEL_NULL(maptext_overlay)
	return ..()

/atom/movable/screen/action_button/proc/get_button_screen_loc(button_number)
	var/row = round((button_number-1)/13) //13 is max amount of buttons per row
	var/col = ((button_number - 1)%(13)) + 1
	var/coord_col = "+[col-1]"
	var/coord_col_offset = 4+2*col
	var/coord_row = "[-1 - row]"
	var/coord_row_offset = 26
	return "WEST[coord_col]:[coord_col_offset],NORTH[coord_row]:[coord_row_offset]"

/atom/movable/screen/action_button/proc/set_maptext(new_maptext, new_maptext_x, new_maptext_y)
	overlays -= maptext_overlay
	maptext_overlay = image(null, null, null, layer + 0.1)
	maptext_overlay.maptext = new_maptext
	if(new_maptext_x)
		maptext_overlay.maptext_x = new_maptext_x
	if(new_maptext_y)
		maptext_overlay.maptext_y = new_maptext_y
	overlays += maptext_overlay

/atom/movable/screen/action_button/hide_toggle
	name = "Hide Buttons"
	icon = 'icons/mob/hud/actions.dmi'
	icon_state = "hide"
	var/hidden = 0

/atom/movable/screen/action_button/hide_toggle/clicked(mob/user, mods)
	user.hud_used.action_buttons_hidden = !user.hud_used.action_buttons_hidden
	hidden = user.hud_used.action_buttons_hidden
	if(hidden)
		name = "Show Buttons"
		icon_state = "show"
	else
		name = "Hide Buttons"
		icon_state = "hide"
	user.update_action_buttons()
	return TRUE

/atom/movable/screen/action_button/ghost/minimap/get_button_screen_loc(button_number)
	return "SOUTH:6,CENTER+1:24"

/atom/movable/screen/storage
	name = "storage"
	layer = HUD_LAYER

/atom/movable/screen/storage/proc/update_fullness(obj/item/storage/master_storage)
	if(!master_storage.contents.len)
		color = null
	else
		var/total_w = 0
		for(var/obj/item/storage_item in master_storage)
			total_w += storage_item.w_class

		//Calculate fullness for etiher max storage, or for storage slots if the container has them
		var/fullness = 0
		if(master_storage.storage_slots == null)
			fullness = round(10*total_w/master_storage.max_storage_space)
		else
			fullness = round(10*master_storage.contents.len/master_storage.storage_slots)
		switch(fullness)
			if(10)
				color = "#ff0000"
			if(7 to 9)
				color = "#ffa500"
			else
				color = null

/atom/movable/screen/gun
	name = "gun"
	dir = SOUTH
	var/gun_click_time = -100

/atom/movable/screen/gun/move
	name = "Allow Walking"
	icon_state = "no_walk0"

/atom/movable/screen/gun/move/update_icon(mob/user)
	if(user.gun_mode)
		if(user.target_can_move)
			icon_state = "no_walk1"
			name = "Disallow Walking"
		else
			icon_state = "no_walk0"
			name = "Allow Walking"
		screen_loc = initial(screen_loc)
		return FALSE
	screen_loc = null

/atom/movable/screen/gun/move/clicked(mob/user)
	if(..())
		return TRUE

	if(gun_click_time > world.time - 30) //give them 3 seconds between mode changes.
		return TRUE
	if(!isgun(user.get_held_item()))
		to_chat(user, "You need your gun in your active hand to do that!")
		return TRUE
	user.AllowTargetMove()
	gun_click_time = world.time
	return TRUE


/atom/movable/screen/gun/run
	name = "Allow Running"
	icon_state = "no_run0"

/atom/movable/screen/gun/run/update_icon(mob/user)
	if(user.gun_mode)
		if(user.target_can_move)
			if(user.target_can_run)
				icon_state = "no_run1"
				name = "Disallow Running"
			else
				icon_state = "no_run0"
				name = "Allow Running"
			screen_loc = initial(screen_loc)
			return FALSE
	screen_loc = null

/atom/movable/screen/gun/run/clicked(mob/user)
	if(..())
		return TRUE

	if(gun_click_time > world.time - 30) //give them 3 seconds between mode changes.
		return TRUE
	if(!isgun(user.get_held_item()))
		to_chat(user, "You need your gun in your active hand to do that!")
		return TRUE
	user.AllowTargetRun()
	gun_click_time = world.time
	return TRUE


/atom/movable/screen/gun/item
	name = "Allow Item Use"
	icon_state = "no_item0"

/atom/movable/screen/gun/item/update_icon(mob/user)
	if(user.gun_mode)
		if(user.target_can_click)
			icon_state = "no_item1"
			name = "Allow Item Use"
		else
			icon_state = "no_item0"
			name = "Disallow Item Use"
		screen_loc = initial(screen_loc)
		return FALSE
	screen_loc = null

/atom/movable/screen/gun/item/clicked(mob/user)
	if(..())
		return TRUE

	if(gun_click_time > world.time - 30) //give them 3 seconds between mode changes.
		return TRUE
	if(!isgun(user.get_held_item()))
		to_chat(user, "You need your gun in your active hand to do that!")
		return TRUE
	user.AllowTargetClick()
	gun_click_time = world.time
	return TRUE


/atom/movable/screen/gun/mode
	name = "Toggle Gun Mode"
	icon_state = "gun0"

/atom/movable/screen/gun/mode/update_icon(mob/user)
	if(user.gun_mode)
		icon_state = "gun1"
	else
		icon_state = "gun0"

/atom/movable/screen/gun/mode/clicked(mob/user)
	if(..())
		return TRUE
	user.ToggleGunMode()
	return TRUE


/atom/movable/screen/zone_sel
	name = "damage zone"
	icon_state = "zone_sel"
	var/selecting = "chest"

/atom/movable/screen/zone_sel/update_icon(mob/living/user)
	overlays.Cut()
	overlays += image('icons/mob/hud/zone_sel.dmi', "[selecting]")
	user.zone_selected = selecting

/atom/movable/screen/zone_sel/clicked(mob/user, list/mods)
	if(..())
		return TRUE

	var/icon_x = text2num(mods["icon-x"])
	var/icon_y = text2num(mods["icon-y"])
	var/old_selecting = selecting //We're only going to update_icon() if there's been a change

	switch(icon_y)
		if(1 to 3) //Feet
			switch(icon_x)
				if(10 to 15)
					selecting = "r_foot"
				if(17 to 22)
					selecting = "l_foot"
				else
					return TRUE
		if(4 to 9) //Legs
			switch(icon_x)
				if(10 to 15)
					selecting = "r_leg"
				if(17 to 22)
					selecting = "l_leg"
				else
					return TRUE
		if(10 to 13) //Hands and groin
			switch(icon_x)
				if(8 to 11)
					selecting = "r_hand"
				if(12 to 20)
					selecting = "groin"
				if(21 to 24)
					selecting = "l_hand"
				else
					return TRUE
		if(14 to 22) //Chest and arms to shoulders
			switch(icon_x)
				if(8 to 11)
					selecting = "r_arm"
				if(12 to 20)
					selecting = "chest"
				if(21 to 24)
					selecting = "l_arm"
				else
					return TRUE
		if(23 to 30) //Head, but we need to check for eye or mouth
			if(icon_x in 12 to 20)
				selecting = "head"
				switch(icon_y)
					if(23 to 24)
						if(icon_x in 15 to 17)
							selecting = "mouth"
					if(26) //Eyeline, eyes are on 15 and 17
						if(icon_x in 14 to 18)
							selecting = "eyes"
					if(25 to 27)
						if(icon_x in 15 to 17)
							selecting = "eyes"

	if(old_selecting != selecting)
		update_icon(user)
	return TRUE

/atom/movable/screen/zone_sel/robot
	icon = 'icons/mob/hud/screen1_robot.dmi'

/atom/movable/screen/clicked(mob/user)
	if(!user)
		return TRUE

	if(isobserver(user))
		return TRUE

	switch(name)
		if("equip")
			if(ishuman(user))
				var/mob/living/carbon/human/human = user
				human.quick_equip()
			return TRUE

		if("Reset Machine")
			user.unset_interaction()
			return TRUE

		if("module")
			if(isSilicon(user))
				if(user:module)
					return TRUE
				user:pick_module()
			return TRUE

		if("radio")
			if(isSilicon(user))
				user:radio_menu()
			return TRUE
		if("panel")
			if(isSilicon(user))
				user:installed_modules()
			return TRUE

		if("store")
			if(isSilicon(user))
				user:uneq_active()
			return TRUE

		if("module1")
			if(isrobot(user))
				user:toggle_module(1)
			return TRUE

		if("module2")
			if(isrobot(user))
				user:toggle_module(2)
			return TRUE

		if("module3")
			if(isrobot(user))
				user:toggle_module(3)
			return TRUE

		if("Activate weapon attachment")
			var/obj/item/weapon/gun/held_item = user.get_held_item()
			if(istype(held_item))
				held_item.activate_attachment_verb()
			return TRUE

		if("Toggle Rail Flashlight")
			var/obj/item/weapon/gun/held_item = user.get_held_item()
			if(istype(held_item))
				held_item.activate_rail_attachment_verb()
			return TRUE

		if("Eject magazine")
			var/obj/item/weapon/gun/held_item = user.get_held_item()
			if(istype(held_item))
				held_item.empty_mag()
			return TRUE

		if("Toggle burst fire")
			var/obj/item/weapon/gun/held_item = user.get_held_item()
			if(istype(held_item))
				held_item.use_toggle_burst()
			return TRUE

		if("Use unique action")
			var/obj/item/weapon/gun/held_item = user.get_held_item()
			if(istype(held_item))
				held_item.use_unique_action()
			return TRUE
	return FALSE


/atom/movable/screen/inventory/clicked(mob/user)
	if(..())
		return TRUE
	if(user.is_mob_incapacitated(TRUE))
		return TRUE
	switch(name)
		if("r_hand")
			if(iscarbon(user))
				var/mob/living/carbon/carbon = user
				carbon.activate_hand("r")
			return TRUE
		if("l_hand")
			if(iscarbon(user))
				var/mob/living/carbon/carbon = user
				carbon.activate_hand("l")
			return TRUE
		if("swap")
			user.swap_hand()
			return TRUE
		if("hand")
			user.swap_hand()
			return TRUE
		else
			if(user.attack_ui(slot_id))
				user.update_inv_l_hand(0)
				user.update_inv_r_hand(0)
				return TRUE
	return FALSE

/atom/movable/screen/throw_catch
	name = "throw/catch"
	icon = 'icons/mob/hud/human_midnight.dmi'
	icon_state = "act_throw_off"

/atom/movable/screen/throw_catch/clicked(mob/user, list/mods)
	var/mob/living/carbon/carbon = user

	if(!istype(carbon))
		return FALSE

	if(user.is_mob_incapacitated())
		return TRUE

	if(mods["ctrl"])
		carbon.toggle_throw_mode(THROW_MODE_HIGH)
	else
		carbon.toggle_throw_mode(THROW_MODE_NORMAL)
	return TRUE

/atom/movable/screen/drop
	name = "drop"
	icon = 'icons/mob/hud/human_midnight.dmi'
	icon_state = "act_drop"
	layer = HUD_LAYER

/atom/movable/screen/drop/clicked(mob/user)
	user.drop_item_v()
	return TRUE


/atom/movable/screen/resist
	name = "resist"
	icon = 'icons/mob/hud/human_midnight.dmi'
	icon_state = "act_resist"
	layer = HUD_LAYER

/atom/movable/screen/resist/clicked(mob/user)
	if(isliving(user))
		var/mob/living/living = user
		living.resist()
		return TRUE

/atom/movable/screen/mov_intent
	name = "run/walk toggle"
	icon = 'icons/mob/hud/human_midnight.dmi'
	icon_state = "running"

/atom/movable/screen/mov_intent/clicked(mob/living/user)
	. = ..()
	if(.)
		return TRUE
	user.toggle_mov_intent()

/mob/living/proc/set_movement_intent(new_intent)
	m_intent = new_intent
	if(hud_used?.move_intent)
		hud_used.move_intent.set_movement_intent_icon(m_intent)
	recalculate_move_delay = TRUE

/mob/living/proc/toggle_mov_intent()
	if(legcuffed)
		to_chat(src, SPAN_NOTICE("You are legcuffed! You cannot run until you get \the [legcuffed] removed!"))
		set_movement_intent(MOVE_INTENT_WALK)
		return FALSE
	switch(m_intent)
		if(MOVE_INTENT_RUN)
			set_movement_intent(MOVE_INTENT_WALK)
		if(MOVE_INTENT_WALK)
			set_movement_intent(MOVE_INTENT_RUN)
	return TRUE

/atom/movable/screen/mov_intent/proc/set_movement_intent_icon(new_intent)
	switch(new_intent)
		if(MOVE_INTENT_WALK)
			icon_state = "walking"
		if(MOVE_INTENT_RUN)
			icon_state = "running"

/mob/living/carbon/xenomorph/toggle_mov_intent()
	. = ..()
	if(.)
		update_icons()
		return TRUE

/atom/movable/screen/act_intent
	name = "intent"
	icon_state = "intent_help"

/atom/movable/screen/act_intent/clicked(mob/user)
	user.a_intent_change()
	return TRUE

/atom/movable/screen/act_intent/corner/clicked(mob/user, list/mods)
	var/_x = text2num(mods["icon-x"])
	var/_y = text2num(mods["icon-y"])

	if(_x<=16 && _y<=16)
		user.a_intent_change(INTENT_HARM)

	else if(_x<=16 && _y>=17)
		user.a_intent_change(INTENT_HELP)

	else if(_x>=17 && _y<=16)
		user.a_intent_change(INTENT_GRAB)

	else if(_x>=17 && _y>=17)
		user.a_intent_change(INTENT_DISARM)

	return TRUE


/atom/movable/screen/healths
	name = "health"
	icon_state = "health0"
	icon = 'icons/mob/hud/human_midnight.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/pull
	name = "stop pulling"
	icon = 'icons/mob/hud/human_midnight.dmi'
	icon_state = "pull0"

/atom/movable/screen/pull/clicked(mob/user)
	if(..())
		return TRUE
	user.stop_pulling()
	return TRUE

/atom/movable/screen/pull/update_icon(mob/user)
	if(!user)
		return FALSE
	if(user.pulling)
		icon_state = "pull"
	else
		icon_state = "pull0"



/atom/movable/screen/squad_leader_locator
	name = "beacon tracker"
	icon = 'icons/mob/hud/human_midnight.dmi'
	icon_state = "trackoff"
	alpha = 0 //invisible
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/squad_leader_locator/clicked(mob/living/carbon/human/user, mods)
	if(!istype(user))
		return FALSE
	var/obj/item/device/radio/headset/earpiece = user.get_type_in_ears(/obj/item/device/radio/headset)
	var/has_access = earpiece.misc_tracking || (user.assigned_squad && user.assigned_squad.radio_freq == earpiece.frequency)
	if(!istype(earpiece) || !earpiece.has_hud || !has_access)
		to_chat(user, SPAN_WARNING("Unauthorized access detected."))
		return FALSE
	if(mods["shift"])
		var/area/current_area = get_area(user)
		to_chat(user, SPAN_NOTICE("You are currently at: <b>[current_area.name]</b>."))
		return FALSE
	else if(mods["alt"])
		earpiece.switch_tracker_target()
		return FALSE
	if(user.get_active_hand())
		return FALSE
	if(user.assigned_squad)
		user.assigned_squad.tgui_interact(user)

/atom/movable/screen/mark_locator
	name = "mark locator"
	icon = 'icons/mob/hud/alien_standard.dmi'
	icon_state = "marker"

/atom/movable/screen/mark_locator/clicked(mob/living/carbon/xenomorph/user, mods)
	if(!istype(user))
		return FALSE
	if(mods["shift"] && user.tracked_marker)
		if(user.observed_xeno == user.tracked_marker)
			user.overwatch(user.tracked_marker, TRUE) //passing in an obj/effect into a proc that expects mob/xenomorph B)
		else
			to_chat(user, SPAN_XENONOTICE("You psychically observe the [user.tracked_marker.mark_meaning.name] resin mark in [get_area_name(user.tracked_marker)]."))
			user.overwatch(user.tracked_marker) //this is so scuffed, sorry if this causes errors
		return FALSE
	if(mods["alt"] && user.tracked_marker)
		user.stop_tracking_resin_mark()
		return FALSE
	if(!user.faction)
		to_chat(user, SPAN_WARNING("You don't belong to a any hive!"))
		return FALSE
	if(!user.faction.living_xeno_queen)
		to_chat(user, SPAN_WARNING("Without a queen your psychic link is broken!"))
		return FALSE
	if(user.burrow || user.is_mob_incapacitated() || user.buckled)
		return FALSE
	user.faction.mark_ui.update_all_data()
	user.faction.mark_ui.open_mark_menu(user)

/atom/movable/screen/queen_locator
	name = "queen locator"
	icon = 'icons/mob/hud/alien_standard.dmi'
	icon_state = "trackoff"
	var/list/track_state = list(TRACKER_QUEEN, 0)

/atom/movable/screen/queen_locator/clicked(mob/living/carbon/xenomorph/user, mods)
	if(!istype(user))
		return FALSE
	if(mods["shift"])
		var/area/current_area = get_area(user)
		to_chat(user, SPAN_NOTICE("You are currently at: <b>[current_area.name]</b>."))
		return FALSE
	if(!user.faction)
		to_chat(user, SPAN_WARNING("You don't belong to a hive!"))
		return FALSE
	if(mods["alt"])
		var/list/options = list()
		if(user.faction.living_xeno_queen)
			options["Queen"] = TRACKER_QUEEN
		if(user.faction.faction_location)
			options["Hive Core"] = TRACKER_HIVE
		var/xeno_leader_index = 1
		for(var/xeno in user.faction.xeno_leader_list)
			var/mob/living/carbon/xenomorph/xeno_lead = user.faction.xeno_leader_list[xeno_leader_index]
			if(xeno_lead)
				options["Xeno Leader [xeno_lead]"] = list(TRACKER_LEADER, xeno_leader_index)
			xeno_leader_index++

		var/tunnel_index = 1
		for(var/obj/structure/tunnel/tracked_tunnel in user.faction.tunnels)
			options["Tunnel [tracked_tunnel.tunnel_desc]"] = list(TRACKER_TUNNEL, tunnel_index)
			tunnel_index++

		var/selected = tgui_input_list(user, "Select what you want the locator to track.", "Locator Options", options)
		if(selected)
			track_state = options[selected]
		return FALSE
	if(!user.faction.living_xeno_queen)
		to_chat(user, SPAN_WARNING("Your hive doesn't have a living queen!"))
		return FALSE
	if(user.burrow || user.is_mob_incapacitated() || user.buckled)
		return FALSE
	user.overwatch(user.faction.living_xeno_queen)

/atom/movable/screen/xenonightvision
	icon = 'icons/mob/hud/alien_standard.dmi'
	name = "toggle night vision"
	icon_state = "nightvision_full"

/atom/movable/screen/xenonightvision/clicked(mob/user)
	if(..())
		return TRUE
	var/mob/living/carbon/xenomorph/X = user
	X.toggle_nightvision()
	update_icon(X)
	return TRUE

/atom/movable/screen/xenonightvision/update_icon(mob/living/carbon/xenomorph/owner)
	. = ..()
	var/vision_define
	switch(owner.lighting_alpha)
		if(LIGHTING_PLANE_ALPHA_INVISIBLE)
			icon_state = "nightvision_full"
			vision_define = XENO_VISION_LEVEL_FULL_NVG
		if(LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			icon_state = "nightvision_half"
			vision_define = XENO_VISION_LEVEL_MID_NVG
		if(LIGHTING_PLANE_ALPHA_VISIBLE)
			icon_state = "nightvision_off"
			vision_define = XENO_VISION_LEVEL_NO_NVG
	to_chat(owner, SPAN_NOTICE("Night vision mode switched to <b>[vision_define]</b>."))

/atom/movable/screen/bodytemp
	name = "body temperature"
	icon_state = "temp0"

/atom/movable/screen/oxygen
	name = "oxygen"
	icon_state = "oxy0"

/atom/movable/screen/toggle_inv
	name = "toggle"
	icon_state = "other"

/atom/movable/screen/toggle_inv/clicked(mob/user)
	if(..())
		return TRUE

	if(user && user.hud_used)
		if(user.hud_used.inventory_shown)
			user.hud_used.inventory_shown = 0
			user.client.screen -= user.hud_used.toggleable_inventory
		else
			user.hud_used.inventory_shown = 1
			user.client.screen += user.hud_used.toggleable_inventory

		user.hud_used.hidden_inventory_update()
	return TRUE

/atom/movable/screen/preview
	icon = 'icons/turf/almayer.dmi'
	icon_state = "blank"
	plane = -100
	layer = TURF_LAYER

#define AMMO_HUD_ICON_NORMAL 1
#define AMMO_HUD_ICON_EMPTY 2
/atom/movable/screen/ammo
	name = "ammo"
	icon = 'icons/mob/hud/ammoHUD.dmi'
	icon_state = "ammo"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = gun_ammo_ui_1
	///If the user has already had their warning played for running out of ammo
	var/warned = FALSE
	///Holder for playing a out of ammo animation so that it doesnt get cut during updates
	var/atom/movable/flash_holder
	///List of possible screen locs
	var/static/list/ammo_screen_loc_list = list(gun_ammo_ui_1, gun_ammo_ui_2, gun_ammo_ui_3, gun_ammo_ui_4)

/atom/movable/screen/ammo/Initialize()
	. = ..()
	flash_holder = new
	flash_holder.icon_state = "frame"
	flash_holder.icon = icon
	flash_holder.plane = plane
	flash_holder.layer = layer+0.001
	flash_holder.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_contents += flash_holder

/atom/movable/screen/ammo/Destroy()
	QDEL_NULL(flash_holder)
	return ..()

///wrapper to add this to the users screen with a owner
/atom/movable/screen/ammo/proc/add_hud(mob/living/user, datum/ammo_owner)
	if(isnull(ammo_owner))
		CRASH("/atom/movable/screen/ammo/proc/add_hud() has been called from [src] without the required param of ammo_owner")
	user?.client.screen += src

///wrapper to removing this ammo hud from the users screen
/atom/movable/screen/ammo/proc/remove_hud(mob/living/user)
	user?.client?.screen -= src

///actually handles upadating the hud
/atom/movable/screen/ammo/proc/update_hud(mob/living/user, list/ammo_type, rounds)
	overlays.Cut()

	if(rounds <= 0)
		overlays += image(icon, src, "o0")
		var/image/empty_state = image(icon, src, ammo_type[AMMO_HUD_ICON_EMPTY])
		overlays += empty_state
		if(warned)
			return
		warned = TRUE
		flick("[ammo_type[AMMO_HUD_ICON_EMPTY]]_flash", flash_holder)
		return

	warned = FALSE
	overlays += image(icon, src, "[ammo_type[AMMO_HUD_ICON_NORMAL]]")

	rounds = num2text(rounds)

	//Handle the amount of rounds
	switch(length_char(rounds))
		if(1)
			overlays += image(icon, src, "o[rounds[1]]")
		if(2)
			overlays += image(icon, src, "o[rounds[2]]")
			overlays += image(icon, src, "t[rounds[1]]")
		if(3)
			overlays += image(icon, src, "o[rounds[3]]")
			overlays += image(icon, src, "t[rounds[2]]")
			overlays += image(icon, src, "h[rounds[1]]")
		else //"0" is still length 1 so this means it's over 999
			overlays += image(icon, src, "o9")
			overlays += image(icon, src, "t9")
			overlays += image(icon, src, "h9")

#undef AMMO_HUD_ICON_NORMAL
#undef AMMO_HUD_ICON_EMPTY

/atom/movable/screen/rotate
	icon_state = "centred_arrow"
	dir = EAST
	var/atom/assigned_atom
	var/rotate_amount = 90

/atom/movable/screen/rotate/Initialize(mapload, set_assigned_atom)
	. = ..()
	assigned_atom = set_assigned_atom

/atom/movable/screen/rotate/clicked(mob/user)
	if(assigned_atom)
		assigned_atom.setDir(turn(assigned_atom.dir, rotate_amount))

/atom/movable/screen/rotate/alt
	dir = WEST
	rotate_amount = -90

/atom/movable/screen/vulture_scope // The part of the vulture's scope that drifts over time
	icon_state = "vulture_unsteady"
	screen_loc = "CENTER,CENTER"
