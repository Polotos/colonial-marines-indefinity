#define WHITELISTFILE "data/whitelist.txt"

GLOBAL_LIST_FILE_LOAD(whitelist, WHITELISTFILE)

/proc/check_whitelist(mob/M /*, rank*/)
	if(!CONFIG_GET(flag/usewhitelist) || !GLOB.whitelist)
		return 0
	return ("[M.ckey]" in GLOB.whitelist)

/proc/can_play_special_job(client/client, job)
	if(client.admin_holder && (client.admin_holder.rights & R_ADMIN))
		return TRUE
	if(job == XENO_CASTE_QUEEN)
		var/datum/caste_datum/C = SSticker.role_authority.castes_by_name[XENO_CASTE_QUEEN]
		return C.can_play_caste(client)
	if(job == JOB_SURVIVOR)
		var/datum/job/J = SSticker.role_authority.roles_by_path[/datum/job/civilian/survivor]
		return J.can_play_role(client)
	return TRUE

GLOBAL_LIST_FILE_LOAD(alien_whitelist, "config/alienwhitelist.txt")

/proc/is_alien_whitelisted(mob/M, species)
	if(!CONFIG_GET(flag/usealienwhitelist)) //If there's not config to use the whitelist.
		return 1
	if(species == "human" || species == "Human")
		return 1
// if(check_rights(R_ADMIN, 0)) //Admins are not automatically considered to be whitelisted anymore. ~N
// return 1 //This actually screwed up a bunch of procs, but I only noticed it with the wrong spawn point.
	if(!CONFIG_GET(flag/usealienwhitelist) || !GLOB.alien_whitelist)
		return 0
	if(M && species)
		for (var/s in GLOB.alien_whitelist)
			if(findtext(lowertext(s),"[lowertext(M.key)] - [species]"))
				return 1
			//if(findtext(lowertext(s),"[lowertext(M.key)] - [species] Elder")) //Unnecessary.
			// return 1
			if(findtext(lowertext(s),"[lowertext(M.key)] - All"))
				return TRUE
	return FALSE

/// returns a list of strings containing the whitelists held by a specific ckey
/proc/get_whitelisted_roles(ckey)
	if(SSticker.role_authority.roles_whitelist[ckey] & WHITELIST_PREDATOR)
		LAZYADD(., "predator")
	if(SSticker.role_authority.roles_whitelist[ckey] & WHITELIST_COMMANDER)
		LAZYADD(., "commander")
	if(SSticker.role_authority.roles_whitelist[ckey] & WHITELIST_SYNTHETIC)
		LAZYADD(., "synthetic")

#undef WHITELISTFILE
