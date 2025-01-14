/datum/player_action/delimb
	action_tag = "mob_delimb"
	name = "Delimb"
	permissions_required = R_VAREDIT

/datum/player_action/delimb/act(client/user, mob/target, list/params)
	if(!params["limbs"] || !ishuman(target))
		return

	var/mob/living/carbon/human/H = target

	for(var/limb in params["limbs"])
		if(!limb)
			continue

		if(!H.has_limb(limb))
			continue

		var/obj/limb/L = H.get_limb(limb)
		L.droplimb(create_cause_data("adminbus"))

	playsound(target, "bone_break", 45, TRUE)
	target.emote("scream")

	return TRUE

/datum/player_action/relimb
	action_tag = "mob_relimb"
	name = "Relimb"
	permissions_required = R_VAREDIT

/datum/player_action/relimb/act(client/user, mob/target, list/params)
	if(!params["limbs"] || !ishuman(target))
		return

	var/mob/living/carbon/human/H = target

	// These will always be last, because they get appended after.
	for(var/limb in params["limbs"])
		switch(limb)
			if("r_leg")
				params["limbs"] += "r_foot"
			if("l_leg")
				params["limbs"] += "l_foot"
			if("r_arm")
				params["limbs"] += "r_hand"
			if("l_arm")
				params["limbs"] += "l_hand"

	for(var/limb in params["limbs"])
		if(!limb)
			continue

		if(H.has_limb(limb))
			continue

		var/obj/limb/L = H.get_limb(limb)

		L.rejuvenate()

	H.pain.recalculate_pain()

	to_chat(target, SPAN_HELPFUL("You feel your limbs regrow back."))

	return TRUE

/datum/player_action/cryo_human
	action_tag = "cryo_human"
	name = "Cryo Human"


/datum/player_action/cryo_human/act(client/user, mob/target, list/params)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.assigned_squad)
			var/datum/squad/S = H.assigned_squad
			if(H.job == JOB_SQUAD_SPECIALIST)
				//we make the set this specialist took if any available again
				if(H.skills)
					var/set_name
					switch(H.skills.get_skill_level(SKILL_SPEC_WEAPONS))
						if(SKILL_SPEC_ROCKET)
							set_name = "Demolitionist Set"
						if(SKILL_SPEC_GRENADIER)
							set_name = "Heavy Grenadier Set"
						if(SKILL_SPEC_PYRO)
							set_name = "Pyro Set"
						if(SKILL_SPEC_SCOUT)
							set_name = "Scout Set"
						if(SKILL_SPEC_SNIPER)
							set_name = "Sniper Set"

					if(set_name && !available_specialist_sets.Find(set_name))
						available_specialist_sets += set_name
			S.forget_marine_in_squad(H)
		message_admins("[key_name_admin(user)] sent [key_name_admin(target)] ([H.job]) to cryogenics.")

	//Handle job slot/tater cleanup.
	SSticker.role_authority.free_role(GET_MAPPED_ROLE(target.job), TRUE)
	SSautobalancer.balance_action(target, "remove")

	//Delete them from datacore.
	var/target_ref = WEAKREF(target)
	for(var/datum/data/record/R as anything in GLOB.data_core.medical)
		if((R.fields["ref"] == target_ref))
			GLOB.data_core.medical -= R
			qdel(R)
	for(var/datum/data/record/T in GLOB.data_core.security)
		if((T.fields["ref"] == target_ref))
			GLOB.data_core.security -= T
			qdel(T)
	for(var/datum/data/record/G in GLOB.data_core.general)
		if((G.fields["ref"] == target_ref))
			GLOB.data_core.general -= G
			qdel(G)

	if(target.key)
		target.ghostize(FALSE)

	qdel(target)
	return TRUE


/datum/player_action/set_speed
	action_tag = "set_speed"
	name = "Set Speed"
	permissions_required = R_VAREDIT

/datum/player_action/set_speed/act(client/user, mob/target, list/params)
	if(isnull(params["speed"]))
		return

	target.speed = text2num(params["speed"])

	return TRUE

/datum/player_action/set_status_flags
	action_tag = "set_status_flags"
	name = "Set Status Flags"
	permissions_required = R_VAREDIT

/datum/player_action/set_status_flags/act(client/user, mob/target, list/params)
	if(isnull(params["status_flags"]))
		return

	target.status_flags = text2num(params["status_flags"])

	return TRUE

/datum/player_action/set_pain
	action_tag = "set_pain"
	name = "Set Pain"
	permissions_required = R_VAREDIT

/datum/player_action/set_pain/act(client/user, mob/target, list/params)
	if(isnull(params["feels_pain"]))
		return

	if(!isliving(target))
		return

	var/mob/living/L = target
	L.pain?.feels_pain = params["feels_pain"]

	return TRUE

/datum/player_action/select_equipment
	action_tag = "select_equipment"
	name = "Select Equipment"
	permissions_required = R_SPAWN

/datum/player_action/select_equipment/act(client/user, mob/target, list/params)
	user.cmd_admin_dress_human(target)
	return TRUE

/datum/player_action/strip_equipment
	action_tag = "strip_equipment"
	name = "Strip Equipment"
	permissions_required = R_SPAWN

/datum/player_action/strip_equipment/act(client/user, mob/target, list/params)
	for (var/obj/item/current_item in target)
		if(istype(current_item, /obj/item/card/id))
			continue

		if(params["drop_items"])
			target.drop_inv_item_to_loc(current_item, target.loc, FALSE, TRUE)
			continue

		qdel(current_item)

	message_admins("[key_name_admin(user)] stripped [target] of their items.")
	return TRUE

/datum/player_action/set_squad
	action_tag = "set_squad"
	name = "Set Squad"
	permissions_required = R_VAREDIT

/datum/player_action/set_squad/act(client/user, mob/living/carbon/human/target, list/params)
	var/list/squads = list()
	for(var/datum/squad/squad in SSticker.role_authority.squads)
		squads[squad.name] = squad

	var/selected_squad = tgui_input_list(user, "Select a squad.", "Squad Selection", squads)
	if(!selected_squad)
		return

	var/success = transfer_marine_to_squad(target, squads[selected_squad], target.assigned_squad, target.get_idcard())

	message_admins("[key_name_admin(user)][success ? "" : " failed to"] set [key_name_admin(target)]'s squad to [selected_squad].")
	return TRUE

/datum/player_action/set_faction
	action_tag = "set_faction"
	name = "Set Faction"
	permissions_required = R_VAREDIT

/datum/player_action/set_faction/act(client/user, mob/living/carbon/target, list/params)
	var/faction_to_get = tgui_input_list(usr, "Select faction", "Faction Choice", FACTION_LIST_ALL)
	if(faction_to_get)
		GLOB.faction_datum[faction_to_get].add_mob(target)

	message_admins("[key_name_admin(user)][faction_to_get ? "" : " failed to"] set [key_name_admin(target)]'s faction to [faction_to_get].")
	return TRUE
