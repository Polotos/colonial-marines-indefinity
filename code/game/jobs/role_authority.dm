/*
How this works:
jobs.dm contains the job defines that work on that level only. Things like equipping a character, creating IDs, and so forth, are handled there.
Role Authority handles the creation and assignment of roles. Roles can be things like regular marines, PMC response teams, aliens, and so forth.
Role Authority creates two master lists on New(), one for every role defined in the game, by path, and one only for roles that should appear
at round start, by name. The title of a role is important and is a unique identifier. Two roles can share the same title, but it's really
the same role, just with different equipment, spawn conditions, or something along those lines. The title is there to tell the job ban system
which roles to ban, and it does so through the roles_by_name master list.

When a round starts, the roles are assigned based on the round, from another list. This is done to make sure that both the master list of roles
by name can be kept for things like job bans, while the round may add or remove roles as needed.If you need to equip a mob for a job, always
use roles_by_path as it is an accurate account of every specific role path (with specific equipment).
*/

#define GET_RANDOM_JOB 0
#define BE_MARINE 1
#define RETURN_TO_LOBBY 2
#define BE_XENOMORPH 3

#define NEVER_PRIORITY 0
#define HIGH_PRIORITY 1
#define MED_PRIORITY 2
#define LOW_PRIORITY 3

#define SHIPSIDE_ROLE_WEIGHT 0.25

var/global/players_preassigned = 0


/proc/guest_jobbans(job)
	return (job in ROLES_COMMAND)

/datum/authority/branch/role
	var/name = "Role Authority"

	var/list/roles_by_path //Master list generated when role aithority is created, listing every role by path, including variable roles. Great for manually equipping with.
	var/list/roles_by_name //Master list generated when role authority is created, listing every default role by name, including those that may not be regularly selected.
	var/list/roles_by_faction
	var/list/roles_for_mode //Derived list of roles only for the game mode, generated when the round starts.
	var/list/roles_whitelist //Associated list of lists, by ckey. Checks to see if a person is whitelisted for a specific role.
	var/list/castes_by_path //Master list generated when role aithority is created, listing every caste by path.
	var/list/castes_by_name //Master list generated when role authority is created, listing every default caste by name.

	/// List of mapped roles that should be used in place of usual ones
	var/list/role_mappings
	var/list/default_roles
	var/max_weigth = 0

	var/list/unassigned_players
	var/list/squads
	var/list/squads_by_type

//Whenever the controller is created, we want to set up the basic role lists.
/datum/authority/branch/role/New()
	var/roles_all[] = typesof(/datum/job) - list( //We want to prune all the parent types that are only variable holders.
											/datum/job,
											/datum/job/command,
											/datum/job/civilian,
											/datum/job/logistics,
											/datum/job/marine,
											/datum/job/antag,
											/datum/job/special,
											/datum/job/special/provost,
											/datum/job/special/uaac,
											/datum/job/special/uaac/tis,
											/datum/job/special/uscm,
											/datum/job/upp,
											/datum/job/upp/command,
											/datum/job/upp/squad,
											/datum/job/special/cmb,
											)
	var/squads_all[] = typesof(/datum/squad) - /datum/squad
	var/castes_all[] = subtypesof(/datum/caste_datum)

	if(!length(roles_all))
		to_world(SPAN_DEBUG("Error setting up jobs, no job datums found."))
		log_debug("Error setting up jobs, no job datums found.")
		return //No real reason this should be length zero, so we'll just return instead.

	if(!length(squads_all))
		to_world(SPAN_DEBUG("Error setting up squads, no squad datums found."))
		log_debug("Error setting up squads, no squad datums found.")
		return

	if(!length(castes_all))
		to_world(SPAN_DEBUG("Error setting up castes, no caste datums found."))
		log_debug("Error setting up castes, no caste datums found.")
		return

	castes_by_path = list()
	castes_by_name = list()
	for(var/caste in castes_all) //Setting up our castes.
		var/datum/caste_datum/C = new caste()

		if(!C.caste_type) //In case you forget to subtract one of those variable holder jobs.
			to_world(SPAN_DEBUG("Error setting up castes, blank caste name: [C.type].</span>"))
			log_debug("Error setting up castes, blank caste name: [C.type].")
			continue

		castes_by_path[C.type] = C
		castes_by_name[C.caste_type] = C

	roles_by_path = list()
	roles_by_name = list()
	roles_by_faction = list()
	for(var/role in roles_all) //Setting up our roles.
		var/datum/job/job = new role()

		if(!job.title) //In case you forget to subtract one of those variable holder jobs.
			to_world(SPAN_DEBUG("Error setting up jobs, blank title job: [job.type]."))
			log_debug("Error setting up jobs, blank title job: [job.type].")
			continue

		roles_by_path[job.type] = job
		roles_by_name[job.title] = job

	set_up_roles()

	squads = list()
	squads_by_type = list()
	for(var/squad in squads_all) //Setting up our squads.
		var/datum/squad/new_squad = new squad()
		squads += new_squad
		squads_by_type[new_squad.type] = new_squad

	load_whitelist()


/datum/authority/branch/role/proc/load_whitelist(filename = "config/role_whitelist.txt")
	var/L[] = file2list(filename)
	var/P[]
	var/W[] = new //We want a temporary whitelist list, in case we need to reload.

	var/i
	var/r
	var/ckey
	var/role
	roles_whitelist = list()
	for(i in L)
		if(!i) continue
		i = trim(i)
		if(!length(i)) continue
		else if(copytext(i, 1, 2) == "#") continue

		P = splittext(i, "+")
		if(!P.len) continue
		ckey = ckey(P[1]) //Converting their key to canonical form. ckey() does this by stripping all spaces, underscores and converting to lower case.

		role = NO_FLAGS
		r = 1
		while(++r <= P.len)
			switch(ckey(P[r]))
				if("yautja") 						role |= WHITELIST_YAUTJA
				if("yautjalegacy") 					role |= WHITELIST_YAUTJA_LEGACY
				if("yautjacouncil")					role |= WHITELIST_YAUTJA_COUNCIL
				if("yautjacouncillegacy")			role |= WHITELIST_YAUTJA_COUNCIL_LEGACY
				if("yautjaleader")					role |= WHITELIST_YAUTJA_LEADER
				if("commander") 					role |= WHITELIST_COMMANDER
				if("commandercouncil")				role |= WHITELIST_COMMANDER_COUNCIL
				if("commandercouncillegacy")		role |= WHITELIST_COMMANDER_COUNCIL_LEGACY
				if("commanderleader")				role |= WHITELIST_COMMANDER_LEADER
				if("workingjoe")					role |= WHITELIST_JOE
				if("synthetic") 					role |= (WHITELIST_SYNTHETIC|WHITELIST_JOE)
				if("syntheticcouncil")				role |= WHITELIST_SYNTHETIC_COUNCIL
				if("syntheticcouncillegacy")		role |= WHITELIST_SYNTHETIC_COUNCIL_LEGACY
				if("syntheticleader")				role |= WHITELIST_SYNTHETIC_LEADER
				if("advisor")						role |= WHITELIST_MENTOR
				if("allgeneral")					role |= WHITELISTS_GENERAL
				if("allcouncil")					role |= (WHITELISTS_COUNCIL|WHITELISTS_GENERAL)
				if("alllegacycouncil")				role |= (WHITELISTS_LEGACY_COUNCIL|WHITELISTS_GENERAL)
				if("everything", "allleader") 		role |= WHITELIST_EVERYTHING

		W[ckey] = role

	roles_whitelist = W

//#undef FACTION_TO_JOIN

/*
Consolidated into a better collection of procs. It was also calling too many loops, and I tried to fix that as well.
I hope it's easier to tell what the heck this proc is even doing, unlike previously.
 */

/datum/authority/branch/role/proc/setup_candidates_and_roles()
	//===============================================================\\
	//PART I: Get roles relevant to the mode

	// Getting role list
	set_up_roles()

	// Also register game mode specific mappings to standard roles
	role_mappings = list()
	default_roles = list()
	if(SSticker.mode.active_roles_mappings_pool)
		for(var/role_path in SSticker.mode.active_roles_mappings_pool)
			var/mapped_title = SSticker.mode.active_roles_mappings_pool[role_path]
			var/datum/job/job = roles_by_path[role_path]
			if(!job || !roles_by_name[mapped_title])
				debug_log("Missing job for prefs: [role_path]")
				continue
			role_mappings[mapped_title] = job
			default_roles[job.title] = mapped_title

	/*===============================================================*/

	//===============================================================\\
	//PART II: Setting up our player variables and lists, to see if we have anyone to destribute.

	unassigned_players = list()
	for(var/mob/new_player/M in GLOB.player_list) //Get all players who are ready.
		if(!M.ready || M.job)
			continue

		unassigned_players += M

	if(!length(unassigned_players)) //If we don't have any players, the round can't start.
		unassigned_players = null
		return

	unassigned_players = shuffle(unassigned_players, 1) //Shuffle the players.


	// How many positions do we open based on total pop
	for(var/i in roles_by_name)
		var/datum/job/job = roles_by_name[i]
		if(job.scaled)
			job.set_spawn_positions(length(unassigned_players))

	/*===============================================================*/

	//===============================================================\\
	//PART III: Here we're doing the main body of the loop and assigning everyone.

	players_preassigned = assign_roles(roles_for_mode, unassigned_players, TRUE)

	// Set up limits for other roles based on our balancing weight number.
	// Set the xeno starting amount based on marines assigned
	for(var/role_name in roles_for_mode)
		var/datum/job/job = roles_for_mode[role_name]
		job.current_positions = 0
		job.set_spawn_positions(players_preassigned)

	// Assign the roles, this time for real, respecting limits we have established.
	var/list/roles_left = assign_roles(roles_for_mode, unassigned_players)

	var/alternate_option_assigned = 0
	for(var/mob/new_player/M in unassigned_players)
		switch(M.client.prefs.alternate_option)
			if(GET_RANDOM_JOB)
				roles_left = assign_random_role(M, roles_left) //We want to keep the list between assignments.
				alternate_option_assigned++
			if(BE_MARINE)
				for(var/base_role in JOB_SQUAD_NORMAL_LIST)
					var/datum/job/job = GET_MAPPED_ROLE(base_role)
					if(assign_role(M, job))
						alternate_option_assigned++
						break

			if(BE_XENOMORPH)
				var/datum/job/xenomorph_job = GET_MAPPED_ROLE(JOB_XENOMORPH)
				assign_role(M, xenomorph_job)
			if(RETURN_TO_LOBBY)
				M.ready = 0
		unassigned_players -= M

	if(length(unassigned_players))
		to_world(SPAN_DEBUG("Error setting up jobs, unassigned_players still has players left. Length of: [length(unassigned_players)]."))
		log_debug("Error setting up jobs, unassigned_players still has players left. Length of: [length(unassigned_players)].")

	unassigned_players = null

	// Now we take spare unfilled xeno slots and make them larva NEW
	var/datum/faction/faction = GLOB.faction_datum[FACTION_XENOMORPH_NORMAL]
	var/datum/job/antag/xenos/xenomorph = GET_MAPPED_ROLE(JOB_XENOMORPH)
	if(istype(faction) && istype(xenomorph))
		faction.stored_larva += max(0, (xenomorph.total_positions - xenomorph.current_positions) \
		+ (xenomorph.calculate_extra_spawn_positions(alternate_option_assigned)))
		faction.faction_ui.update_burrowed_larva()

	/*===============================================================*/

/datum/authority/branch/role/proc/set_up_roles()
	roles_for_mode = list()
	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction = GLOB.faction_datum[faction_to_get]
		if(length(faction.roles_list[SSticker.mode.name]))
			for(var/role_name in faction.roles_list[SSticker.mode.name])
				var/datum/job/job = roles_by_name[role_name]
				if(!job)
					debug_log("Missing job for prefs: [role_name]")
					continue
				roles_for_mode[role_name] = job
				roles_by_faction[role_name] = faction.faction_name

/**
* Assign roles to the players. Return roles that are still avialable.
* If count is true, return role balancing weight instead.
*/
/datum/authority/branch/role/proc/assign_roles(list/roles_to_iterate, list/unassigned_players, count = FALSE)
	var/list/roles_left = list()
	var/assigned = 0
	for(var/priority in HIGH_PRIORITY to LOW_PRIORITY)
		if(count)
			assigned += assign_initial_roles(priority, roles_to_iterate, unassigned_players)
		else
			roles_left = assign_initial_roles(priority, roles_to_iterate, unassigned_players, FALSE)
	if(count)
		return assigned
	return roles_left

/datum/authority/branch/role/proc/assign_initial_roles(priority, list/roles_to_iterate, list/unassigned_players, count = TRUE)
	var/assigned = 0
	if(!length(roles_to_iterate) || !length(unassigned_players))
		return

	for(var/role_name in roles_to_iterate)
		var/datum/job/job = roles_to_iterate[role_name]
		if(!istype(job)) //Shouldn't happen, but who knows.
			to_world(SPAN_DEBUG("Error setting up jobs, no job datum set for: [role_name]."))
			log_debug("Error setting up jobs, no job datum set for: [role_name].")
			continue

		for(var/M in unassigned_players)
			var/mob/new_player/NP = M
			if(!(NP.client.prefs.get_job_priority(job.title) == priority))
				continue //If they don't want the job. //TODO Change the name of the prefs proc?

			if(assign_role(NP, job))
				assigned++
				unassigned_players -= NP
				// -1 check is not strictly needed here, since standard marines are
				// supposed to have an actual spawn_positions number at this point
				if(job.spawn_positions != -1 && job.current_positions >= job.spawn_positions)
					roles_to_iterate -= role_name //Remove the position, since we no longer need it.
					break //Maximum position is reached?

		if(!length(unassigned_players))
			break //No players left to assign? Break.

	if(count)
		return assigned
	return roles_to_iterate

/datum/authority/branch/role/proc/assign_random_role(mob/new_player/M, list/roles_to_iterate) //In case we want to pass on a list.
	. = roles_to_iterate
	if(length(roles_to_iterate))
		var/datum/job/job
		var/i = 0
		var/role_name
		while(++i < 3) //Get two passes.
			if(!length(roles_to_iterate) || prob(65))
				break //Base chance to become a marine when being assigned randomly, or there are no roles available.
			role_name = pick(roles_to_iterate)
			job = roles_to_iterate[role_name]

			if(!istype(job))
				to_world(SPAN_DEBUG("Error setting up jobs, no job datum set for: [role_name]."))
				log_debug("Error setting up jobs, no job datum set for: [role_name].")
				continue

			if(assign_role(M, job)) //Check to see if they can actually get it.
				if(job.current_positions >= job.spawn_positions) roles_to_iterate -= role_name
				return roles_to_iterate

	//If they fail the two passes, or no regular roles are available, they become a marine regardless.
	for(var/base_role in JOB_SQUAD_NORMAL_LIST)
		var/datum/job/job = GET_MAPPED_ROLE(base_role)
		if(assign_role(M, job))
			break

/datum/authority/branch/role/proc/assign_role(mob/new_player/M, datum/job/job, latejoin = FALSE)
	if(ismob(M) && istype(job))
		var/datum/faction/faction = GLOB.faction_datum[roles_by_faction[job.title]]
		var/check_result = check_role_entry(M, job, faction, latejoin)
		if(!check_result)
			M.job = job.title
			job.current_positions++
			return TRUE
		else if(latejoin)
			to_chat(M, "[job.title]: [check_result]")

/datum/authority/branch/role/proc/check_role_entry(mob/new_player/M, datum/job/job, datum/faction/faction, latejoin = FALSE)
	if(jobban_isbanned(M, job.title) || (job.role_ban_alternative && jobban_isbanned(M, job.role_ban_alternative)))
		return  M.client.auto_lang(LANGUAGE_JS_JOBBANED)
	if(!job.can_play_role(M.client))
		return  M.client.auto_lang(LANGUAGE_JS_CANT_PLAY)
	if(job.flags_startup_parameters & ROLE_WHITELISTED && !(roles_whitelist[M.ckey] & job.flags_whitelist))
		return  M.client.auto_lang(LANGUAGE_JS_WHITELIST)
	if(job.total_positions != -1 && job.get_total_positions(latejoin) <= job.current_positions)
		return  M.client.auto_lang(LANGUAGE_JS_NO_SLOTS_OPEN)
	if(latejoin && !job.late_joinable)
		return  M.client.auto_lang(LANGUAGE_JS_CLOSED)
	if(!SSautobalancer.can_join(faction))
		return M.client.auto_lang(LANGUAGE_JS_BALANCE_ISSUE)
	return FALSE

/datum/authority/branch/role/proc/free_role(datum/job/job, latejoin = 1) //Want to make sure it's a job, and nothing like a MODE or special role.
	if(istype(job) && job.total_positions != -1 && job.get_total_positions(latejoin) >= job.current_positions)
		job.current_positions--
		return TRUE

/datum/authority/branch/role/proc/free_role_admin(datum/job/job, latejoin = 1, user) //Specific proc that used for admin "Free Job Slots" verb (round tab)
	if(!istype(job) || job.total_positions == -1)
		return

	if(job.current_positions < 1) //this should be filtered earlier, but we still check just in case
		to_chat(user, "There are no [job] job slots occupied.")
		return

//here is the main reason this proc exists - to remove freed squad jobs from squad,
//so latejoining person ends in the squad which's job was freed and not random one
	var/datum/squad/sq = null
	var/real_job = GET_DEFAULT_ROLE(job)
	if(real_job in JOB_SQUAD_ROLES_LIST)
		var/list/squad_list = list()
		for(sq in SSticker.role_authority.squads)
			if(sq.usable)
				squad_list += sq
		sq = null
		sq = input(user, "Select squad you want to free [job.title] slot from.", "Squad Selection")  as null|anything in squad_list
		if(!sq)
			return
		if(real_job in JOB_SQUAD_ENGI_LIST)
			if(sq.num_engineers > 0)
				sq.num_engineers--
			else
				to_chat(user, "There are no [job.title] slots occupied in [sq.name] Squad.")
				return
		else if(real_job in JOB_SQUAD_MEDIC_LIST)
			if(sq.num_medics > 0)
				sq.num_medics--
			else
				to_chat(user, "There are no [job.title] slots occupied in [sq.name] Squad.")
				return
		else if(real_job in JOB_SQUAD_SPEC_LIST)
			if(sq.num_specialists > 0)
				sq.num_specialists--
			else
				to_chat(user, "There are no [job.title] slots occupied in [sq.name] Squad.")
				return
		else if(real_job in JOB_SQUAD_MAIN_SUP_LIST)
			if(sq.num_smartgun > 0)
				sq.num_smartgun--
			else
				to_chat(user, "There are no [job.title] slots occupied in [sq.name] Squad.")
				return
		else if(real_job in JOB_SQUAD_SUP_LIST)
			if(sq.num_tl > 0)
				sq.num_tl--
			else
				to_chat(user, "There are no [job.title] slots occupied in [sq.name] Squad.")
				return
		else if(real_job in JOB_SQUAD_LEADER_LIST)
			if(sq.num_leaders > 0)
				sq.num_leaders--
			else
				to_chat(user, "There are no [job.title] slots occupied in [sq.name] Squad.")
				return
	job.current_positions--
	message_admins("[key_name(user)] freed the [job.title] job slot[sq ? " in [sq.name] Squad" : ""].")
	return 1

/datum/authority/branch/role/proc/modify_role(datum/job/job, amount)
	if(!istype(job))
		return 0
	if(amount < job.current_positions) //we should be able to slot everyone
		return 0
	job.total_positions = amount
	job.total_positions_so_far = amount
	return 1

//I'm not entirely sure why this proc exists. //TODO Figure this out.
/datum/authority/branch/role/proc/reset_roles()
	for(var/mob/new_player/M in GLOB.new_player_list)
		M.job = null


/datum/authority/branch/role/proc/equip_role(mob/living/M, datum/job/job, turf/late_join)
	if(!istype(M) || !istype(job))
		return

	. = TRUE

	if(!ishuman(M))
		return

	var/mob/living/carbon/human/human = M

	var/job_whitelist = job.title
	var/whitelist_status = job.get_whitelist_status(roles_whitelist, human.client)
	if(job.job_options && human?.client?.prefs?.pref_special_job_options[job.title])
		job.handle_job_options(human.client.prefs.pref_special_job_options[job.title])

	if(whitelist_status)
		job_whitelist = "[job.title][whitelist_status]"

	human.job = job.title //TODO Why is this a mob variable at all?

	if(job.gear_preset_whitelist[job_whitelist])
		arm_equipment(human, job.gear_preset_whitelist[job_whitelist], FALSE, TRUE)
		var/generated_account = job.generate_money_account(human)
		job.announce_entry_message(human, generated_account, whitelist_status) //Tell them their spawn info.
		job.generate_entry_conditions(human, whitelist_status) //Do any other thing that relates to their spawn.
	else
		arm_equipment(human, job.gear_preset, FALSE, TRUE) //After we move them, we want to equip anything else they should have.
		var/generated_account = job.generate_money_account(human)
		job.announce_entry_message(human, generated_account) //Tell them their spawn info.
		job.generate_entry_conditions(human) //Do any other thing that relates to their spawn.

	if(job.flags_startup_parameters & ROLE_ADD_TO_SQUAD) //Are we a muhreen? Randomize our squad. This should go AFTER IDs. //TODO Robust this later.
		randomize_squad(human)

	if(Check_WO() && JOB_SQUAD_ROLES_LIST & GET_DEFAULT_ROLE(human.job)) //activates self setting proc for marine headsets for WO
		var/datum/game_mode/whiskey_outpost/wo = SSticker.mode
		wo.self_set_headset(human)

	var/assigned_squad
	if(human.assigned_squad)
		assigned_squad = human.assigned_squad.name

	if(isturf(late_join))
		human.forceMove(late_join)
	else if(late_join)
		human.forceMove(job.get_latejoin_turf(human))
	else
		var/turf/join_turf
		if(!late_join)
			if(assigned_squad && GLOB.spawns_by_squad_and_job[assigned_squad] && GLOB.spawns_by_squad_and_job[assigned_squad][job.type])
				join_turf = get_turf(pick(GLOB.spawns_by_squad_and_job[assigned_squad][job.type]))
			else if(GLOB.spawns_by_job[job.type])
				join_turf = get_turf(pick(GLOB.spawns_by_job[job.type]))

		if(!join_turf)
			join_turf = job.get_latejoin_turf(human)

		human.forceMove(join_turf)

	for(var/cardinal in GLOB.cardinals)
		var/obj/structure/machinery/cryopod/pod = locate() in get_step(human, cardinal)
		if(pod)
			pod.go_in_cryopod(human, silent = TRUE)
			break

	human.sec_hud_set_ID()
	human.hud_set_squad()

	SSround_recording.recorder.track_player(human)

//Find which squad has the least population. If all 4 squads are equal it should just use a random one
/datum/authority/branch/role/proc/get_lowest_squad(mob/living/carbon/human/human)
	if(!squads.len) //Something went wrong, our squads aren't set up.
		to_world("Warning, something messed up in get_lowest_squad(). No squads set up!")
		return null


	//we make a list of squad that is randomized so alpha isn't always lowest squad.
	var/list/squads_copy = squads.Copy()
	var/list/mixed_squads = list()

	for(var/i= 1 to squads_copy.len)
		var/datum/squad/squad = pick_n_take(squads_copy)
		if(squad.roundstart && squad.usable && squad.faction == human.faction.faction_name && squad.name != "Root")
			mixed_squads += squad

	var/datum/squad/lowest = pick(mixed_squads)

	var/datum/squad/preferred_squad
	if(human && human.client && human.client.prefs.preferred_squad && human.client.prefs.preferred_squad != "None")
		preferred_squad = SQUAD_BY_FACTION[human.faction.faction_name][SQUAD_SELECTOR[human.client.prefs.preferred_squad]]

	for(var/datum/squad/lowest_squad in mixed_squads)
		if(lowest_squad.usable)
			if(preferred_squad)
				lowest = lowest_squad
				break

	if(!lowest)
		to_world("Warning! Bug in get_random_squad()!")
		return null

	var/lowest_count = lowest.count
	var/current_count = 0

	if(!preferred_squad)
		//Loop through squads.
		for(var/datum/squad/squad in mixed_squads)
			if(!squad)
				to_world("Warning: Null squad in get_lowest_squad. Call a coder!")
				break //null squad somehow, let's just abort
			current_count = squad.count //Grab our current squad's #
			if(current_count >= (lowest_count - 2)) //Current squad count is not much lower than the chosen one. Skip it.
				continue
			lowest_count = current_count //We found a winner! This squad is much lower than our default. Make it the new default.
			lowest = squad //'Select' this squad.

	return lowest //Return whichever squad won the competition.

//This proc is a bit of a misnomer, since there's no actual randomization going on.
/datum/authority/branch/role/proc/randomize_squad(mob/living/carbon/human/human, skip_limit = FALSE)
	if(!human)
		return

	if(!length(squads))
		to_chat(human, "Something went wrong with your squad randomizer! Tell a coder!")
		return //Shit, where's our squad data

	if(human.assigned_squad) //Wait, we already have a squad. Get outta here!
		return

	//we make a list of squad that is randomized so alpha isn't always lowest squad.
	var/list/squads_copy = squads.Copy()
	var/list/mixed_squads = list()
	// The following code removes non useable squads from the lists of squads we assign marines too.
	for(var/i= 1 to squads_copy.len)
		var/datum/squad/squad = pick_n_take(squads_copy)
		if(squad.roundstart && squad.usable && squad.faction == human.faction.faction_name && squad.name != "Root")
			mixed_squads += squad

	//Deal with IOs first
	if(human.job == JOB_INTEL)
		var/datum/squad/intel_squad = get_squad_by_name(SQUAD_MARINE_7)
		if(!intel_squad || !istype(intel_squad)) //Something went horribly wrong!
			to_chat(human, "Something went wrong with randomize_squad()! Tell a coder!")
			return
		intel_squad.put_marine_in_squad(human) //Found one, finish up
		return

	//Deal with non-standards first.
	//Non-standards are distributed regardless of squad population.
	//If the number of available positions for the job are more than max_whatever, it will break.
	//Ie. 8 squad medic jobs should be available, and total medics in squads should be 8.
	var/real_job = GET_DEFAULT_ROLE(human.job)
	if(!(real_job in JOB_SQUAD_NORMAL_LIST) && human.job != "Reinforcements")
		var/datum/squad/preferred_squad
		if(human && human.client && human.client.prefs.preferred_squad && human.client.prefs.preferred_squad != "None")
			preferred_squad = squads_by_type[SQUAD_BY_FACTION[human.faction.faction_name][SQUAD_SELECTOR[human.client.prefs.preferred_squad]]]

		var/datum/squad/lowest

		if(real_job in JOB_SQUAD_ENGI_LIST)
			for(var/datum/squad/squad in mixed_squads)
				if(squad.usable && squad.roundstart)
					if(!skip_limit && squad.num_engineers >= squad.max_engineers)
						continue
					if(squad == preferred_squad)
						squad.put_marine_in_squad(human) //fav squad has a spot for us, no more searching needed.
						return

					if(!lowest)
						lowest = squad
					else if(squad.num_engineers < lowest.num_engineers)
						lowest = squad

		else if(real_job in JOB_SQUAD_MEDIC_LIST)
			for(var/datum/squad/squad in mixed_squads)
				if(squad.usable && squad.roundstart)
					if(!skip_limit && squad.num_medics >= squad.max_medics)
						continue
					if(squad == preferred_squad)
						squad.put_marine_in_squad(human) //fav squad has a spot for us.
						return

					if(!lowest)
						lowest = squad
					else if(squad.num_medics < lowest.num_medics)
						lowest = squad

		else if(real_job in JOB_SQUAD_LEADER_LIST)
			for(var/datum/squad/squad in mixed_squads)
				if(squad.usable && squad.roundstart)
					if(!skip_limit && squad.num_leaders >= squad.max_leaders)
						continue
					if(squad == preferred_squad)
						squad.put_marine_in_squad(human) //fav squad has a spot for us.
						return

					if(!lowest)
						lowest = squad
					else if(squad.num_leaders < lowest.num_leaders)
						lowest = squad

		else if(real_job in JOB_SQUAD_SPEC_LIST)
			for(var/datum/squad/squad in mixed_squads)
				if(squad.usable && squad.roundstart)
					if(!skip_limit && squad.num_specialists >= squad.max_specialists)
						continue
					if(squad == preferred_squad)
						squad.put_marine_in_squad(human) //fav squad has a spot for us.
						return

					if(!lowest)
						lowest = squad
					else if(squad.num_specialists < lowest.num_specialists)
						lowest = squad

		else if(real_job in JOB_SQUAD_SUP_LIST)
			for(var/datum/squad/squad in mixed_squads)
				if(squad.usable && squad.roundstart)
					if(!skip_limit && squad.num_tl >= squad.max_tl)
						continue
					if(squad == preferred_squad)
						squad.put_marine_in_squad(human) //fav squad has a spot for us.
						return

					if(!lowest)
						lowest = squad
					else if(squad.num_tl < lowest.num_tl)
						lowest = squad

		else if(real_job in JOB_SQUAD_MAIN_SUP_LIST)
			for(var/datum/squad/squad in mixed_squads)
				if(squad.usable && squad.roundstart)
					if(!skip_limit && squad.num_smartgun >= squad.max_smartgun)
						continue
					if(squad == preferred_squad)
						squad.put_marine_in_squad(human) //fav squad has a spot for us.
						return

					if(!lowest)
						lowest = squad
					else if(squad.num_smartgun < lowest.num_smartgun)
						lowest = squad
		if(!lowest)
			var/ranpick = rand(1,4)
			lowest = mixed_squads[ranpick]
		else
			if(!lowest.put_marine_in_squad(human))
				to_chat(human, "Something went badly with randomize_squad()! Tell a coder!")

	else
		//Deal with marines. They get distributed to the lowest populated squad.
		var/datum/squad/given_squad = get_lowest_squad(human)
		if(!given_squad || !istype(given_squad)) //Something went horribly wrong!
			to_chat(human, "Something went wrong with randomize_squad()! Tell a coder!")
			return
		given_squad.put_marine_in_squad(human) //Found one, finish up

/datum/authority/branch/role/proc/get_caste_by_text(name)
	var/mob/living/carbon/xenomorph/M
	switch(name) //ADD NEW CASTES HERE!
		if(XENO_CASTE_LARVA)
			M = /mob/living/carbon/xenomorph/larva
		if(XENO_CASTE_PREDALIEN_LARVA)
			M = /mob/living/carbon/xenomorph/larva/predalien
		if(XENO_CASTE_FACEHUGGER)
			M = /mob/living/carbon/xenomorph/facehugger
		if(XENO_CASTE_LESSER_DRONE)
			M = /mob/living/carbon/xenomorph/lesser_drone
		if(XENO_CASTE_RUNNER)
			M = /mob/living/carbon/xenomorph/runner
		if(XENO_CASTE_DRONE)
			M = /mob/living/carbon/xenomorph/drone
		if(XENO_CASTE_CARRIER)
			M = /mob/living/carbon/xenomorph/carrier
		if(XENO_CASTE_HIVELORD)
			M = /mob/living/carbon/xenomorph/hivelord
		if(XENO_CASTE_BURROWER)
			M = /mob/living/carbon/xenomorph/burrower
		if(XENO_CASTE_PRAETORIAN)
			M = /mob/living/carbon/xenomorph/praetorian
		if(XENO_CASTE_RAVAGER)
			M = /mob/living/carbon/xenomorph/ravager
		if(XENO_CASTE_SENTINEL)
			M = /mob/living/carbon/xenomorph/sentinel
		if(XENO_CASTE_SPITTER)
			M = /mob/living/carbon/xenomorph/spitter
		if(XENO_CASTE_LURKER)
			M = /mob/living/carbon/xenomorph/lurker
		if(XENO_CASTE_WARRIOR)
			M = /mob/living/carbon/xenomorph/warrior
		if(XENO_CASTE_DEFENDER)
			M = /mob/living/carbon/xenomorph/defender
		if(XENO_CASTE_QUEEN)
			M = /mob/living/carbon/xenomorph/queen
		if(XENO_CASTE_CRUSHER)
			M = /mob/living/carbon/xenomorph/crusher
		if(XENO_CASTE_BOILER)
			M = /mob/living/carbon/xenomorph/boiler
		if(XENO_CASTE_PREDALIEN)
			M = /mob/living/carbon/xenomorph/predalien
		if(XENO_CASTE_HELLHOUND)
			M = /mob/living/carbon/xenomorph/hellhound
	return M


/proc/get_desired_status(desired_status, status_limit)
	var/found_desired = FALSE
	var/found_limit = FALSE

	for(var/status in WHITELIST_HIERARCHY)
		if(status == desired_status)
			found_desired = TRUE
			break
		if(status == status_limit)
			found_limit = TRUE
			break

	if(found_desired)
		return desired_status
	else if(found_limit)
		return status_limit

	return desired_status

/proc/transfer_marine_to_squad(mob/living/carbon/human/transfer_marine, datum/squad/new_squad, datum/squad/old_squad, obj/item/card/id/ID)
	if(old_squad)
		if(transfer_marine.assigned_fireteam)
			if(old_squad.fireteam_leaders["FT[transfer_marine.assigned_fireteam]"] == transfer_marine)
				old_squad.unassign_ft_leader(transfer_marine.assigned_fireteam, TRUE, FALSE)
			old_squad.unassign_fireteam(transfer_marine, TRUE) //reset fireteam assignment
		old_squad.remove_marine_from_squad(transfer_marine, ID)
		old_squad.update_free_mar()
	. = new_squad.put_marine_in_squad(transfer_marine, ID)
	if(.)
		new_squad.update_free_mar()

		var/marine_ref = WEAKREF(transfer_marine)
		for(var/datum/data/record/t in GLOB.data_core.general) //we update the crew manifest
			if(t.fields["ref"] == marine_ref)
				t.fields["squad"] = new_squad.name
				break

		transfer_marine.hud_set_squad()

// returns TRUE if transfer_marine's role is at max capacity in the new squad
/datum/authority/branch/role/proc/check_squad_capacity(mob/living/carbon/human/transfer_marine, datum/squad/new_squad)
	var/real_job = GET_DEFAULT_ROLE(transfer_marine.job)
	if(real_job in JOB_SQUAD_LEADER_LIST)
		if(new_squad.num_leaders >= new_squad.max_leaders)
			return TRUE
	else if(real_job in JOB_SQUAD_SPEC_LIST)
		if(new_squad.num_specialists >= new_squad.max_specialists)
			return TRUE
	else if(real_job in JOB_SQUAD_ENGI_LIST)
		if(new_squad.num_engineers >= new_squad.max_engineers)
			return TRUE
	else if(real_job in JOB_SQUAD_MEDIC_LIST)
		if(new_squad.num_medics >= new_squad.max_medics)
			return TRUE
	else if(real_job in JOB_SQUAD_MAIN_SUP_LIST)
		if(new_squad.num_smartgun >= new_squad.max_smartgun)
			return TRUE
	else if(real_job in JOB_SQUAD_SUP_LIST)
		if(new_squad.num_tl >= new_squad.max_tl)
			return TRUE
	return FALSE
