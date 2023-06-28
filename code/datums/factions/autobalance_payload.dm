/datum/autobalance_row_faction_info
	var/datum/faction/faction
	var/esteminated_power = 0
	var/weight = 0
	var/average_fires = 0
	var/list/round_start_pop = new(3)
	var/list/average_pop = new(3)
	var/list/last_pop = new(3)

/datum/autobalance_row_faction_info/New(datum/faction/faction_to_set)
	..()
	faction = faction_to_set

/datum/autobalance_row_faction_info/proc/esteminate_faction_info()
	var/new_esteminated_power = 0
	var/new_weight = 0
	average_fires++
	last_pop = new(3)
	for(var/potantial_row in SSautobalancer.balance_rows)
		var/datum/autobalance_row_info/balance_row = SSautobalancer.balance_rows[potantial_row]
		if(balance_row.faction_to_set() == faction)
			var/role_coeff = faction.get_role_coeff(balance_row.client.mob.job)
			new_esteminated_power += balance_row.get_player_rating() * role_coeff
			new_weight += role_coeff
			average_pop[balance_row.active]++
			last_pop[balance_row.active]++

	new_esteminated_power += last_pop[1] - average_pop[1] * 100
	new_esteminated_power += last_pop[2] - average_pop[2] * 100
	new_esteminated_power += last_pop[3] - round_start_pop[3] * average_pop[3]

	esteminated_power = new_esteminated_power
	weight = new_weight
	return esteminated_power

/datum/autobalance_row_faction_info/proc/round_start()
	for(var/potantial_row in SSautobalancer.balance_rows)
		var/datum/autobalance_row_info/balance_row = SSautobalancer.balance_rows[potantial_row]
		if(balance_row.faction_to_set() == faction)
			round_start_pop[balance_row.active]++

/datum/autobalance_formula_row
	var/statistic_type = BALANCE_FORMULA_MISC

/datum/autobalance_formula_row/proc/calculate(mob/calculationg_mob, datum/player_entity/entity)
	var/datum/statistic_groups/group = entity.statistics[calculationg_mob.faction.faction_name]
	if(group)
		var/list/stats = list()
		for(var/group_subtype in group.statistic_info)
			var/datum/player_statistic/player_statistic = group.statistic_info[group_subtype]
			for(var/subtype in player_statistic.total)
				stats += list(list("name" = subtype, "value" = player_statistic.total[subtype]))

		return formula_calculate(calculationg_mob, entity, stats)

/datum/autobalance_formula_row/proc/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/total_encounters = 0
	var/total_value = 0
	for(var/potential_stat in stats)
		if(potential_stat in STATISTIC_MISC_ALL)
			total_encounters++
			total_value += stats[potential_stat]
	if(total_value)
		final_calculations += total_value / total_encounters
	return final_calculations

/datum/autobalance_formula_row/commanding
	statistic_type = BALANCE_FORMULA_COMMANDING

/datum/autobalance_formula_row/commanding/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/total_value = 0
	for(var/potential_stat in stats)
		if(potential_stat in STATISTIC_ALL)
			total_value += stats[potential_stat]
	if(total_value)
		final_calculations += total_value / length(STATISTIC_ALL)
	return final_calculations

/datum/autobalance_formula_row/field
	statistic_type = BALANCE_FORMULA_FIELD

/datum/autobalance_formula_row/field/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/list/kda = new(2)
	var/list/shots = new(2)
	var/damage = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTICS_KILL)
				kda[1] += stats[potential_stat]
			if(STATISTICS_KILL_FF)
				kda[1] -= stats[potential_stat]
			if(STATISTICS_DEATH)
				kda[2] += stats[potential_stat]
			if(STATISTICS_DEATH_FF)
				kda[2] -= stats[potential_stat]
			if(STATISTICS_SHOT)
				shots[1] += stats[potential_stat]
			if(STATISTICS_SHOT_HIT)
				shots[2] += stats[potential_stat]
			if(STATISTICS_FF_SHOT_HIT)
				shots[2] -= stats[potential_stat]
			if(STATISTICS_DAMAGE)
				damage += stats[potential_stat]
			if(STATISTICS_FF_DAMAGE)
				damage -= stats[potential_stat]

	if(kda[1] && kda[2])
		final_calculations += kda[1] / kda[2] * 100
	if(shots[1] && shots[2])
		final_calculations += shots[2] / shots[1] * 100
	if(damage && kda[1])
		final_calculations += damage / kda[1]
	return final_calculations


/datum/autobalance_formula_row/support
	statistic_type = BALANCE_FORMULA_SUPPORT

/datum/autobalance_formula_row/support/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/stats_assists = 0
	var/rounds = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTIC_ASSIST_ALL)
				stats_assists += stats[potential_stat]
			if(STATISTICS_ROUNDS_PLAYED)
				rounds += stats[potential_stat]

	if(stats_assists)
		final_calculations += stats_assists / rounds
	return final_calculations

/datum/autobalance_formula_row/support/medic
	statistic_type = BALANCE_FORMULA_MEDIC

/datum/autobalance_formula_row/support/medic/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/healed = 0
	var/revives = 0
	var/rounds = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTICS_HEALED_DAMAGE)
				healed += stats[potential_stat]
			if(STATISTICS_REVIVE)
				revives += stats[potential_stat]
			if(STATISTICS_ROUNDS_PLAYED)
				rounds += stats[potential_stat]

	if(healed)
		final_calculations += healed / rounds
	if(revives)
		final_calculations += revives / rounds * 100
	return final_calculations

/datum/autobalance_formula_row/support/operations
	statistic_type = BALANCE_FORMULA_OPERATIONS

/datum/autobalance_formula_row/support/operations/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/surgeries = 0
	var/rounds = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTIC_SURGERY_ALL)
				surgeries += stats[potential_stat]
			if(STATISTICS_ROUNDS_PLAYED)
				rounds += stats[potential_stat]

	if(surgeries)
		final_calculations += surgeries / rounds
	return final_calculations

/datum/autobalance_formula_row/support/engineer
	statistic_type = BALANCE_FORMULA_ENGINEER

/datum/autobalance_formula_row/support/engineer/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/engi_stats = 0
	var/rounds = 0
	for(var/potential_stat in stats)
		if(potential_stat in STATISTIC_ENGINEERING_ALL)
			engi_stats += stats[potential_stat]
		else if(potential_stat == STATISTICS_ROUNDS_PLAYED)
			rounds += stats[potential_stat]

	if(engi_stats)
		final_calculations += engi_stats / rounds * 100
	return final_calculations

/datum/autobalance_formula_row/xeno_fighter
	statistic_type = BALANCE_FORMULA_XENO_FIGHTER

/datum/autobalance_formula_row/xeno_fighter/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/list/kda = new(2)
	var/slashes = 0
	var/damage = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTICS_KILL)
				kda[1] += stats[potential_stat]
			if(STATISTICS_KILL_FF)
				kda[1] -= stats[potential_stat]
			if(STATISTICS_DEATH)
				kda[2] += stats[potential_stat]
			if(STATISTICS_DEATH_FF)
				kda[2] -= stats[potential_stat]
			if(STATISTICS_SLASH)
				slashes += stats[potential_stat]
			if(STATISTICS_DAMAGE)
				damage += stats[potential_stat]
			if(STATISTICS_FF_DAMAGE)
				damage -= stats[potential_stat]

	if(kda[1] && kda[2])
		final_calculations += kda[1] / kda[2] * 100
	if(slashes && kda[1])
		final_calculations += slashes / kda[1]
	if(damage && kda[1])
		final_calculations += damage / kda[1]
	return final_calculations

/datum/autobalance_formula_row/xeno_healer
	statistic_type = BALANCE_FORMULA_XENO_HEALER

/datum/autobalance_formula_row/xeno_healer/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/healed = 0
	var/rounds = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTICS_HEALED_DAMAGE)
				healed += stats[potential_stat]
			if(STATISTICS_ROUNDS_PLAYED)
				rounds += stats[potential_stat]

	if(healed)
		final_calculations += healed / rounds
	return final_calculations

/datum/autobalance_formula_row/xeno_builder
	statistic_type = BALANCE_FORMULA_XENO_BUILDER

/datum/autobalance_formula_row/xeno_builder/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/build = 0
	var/rounds = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTIC_XENO_STRUCTURES_BUILD)
				build += stats[potential_stat]
			if(STATISTICS_ROUNDS_PLAYED)
				rounds += stats[potential_stat]

	if(build)
		final_calculations += build / rounds
	return final_calculations

/datum/autobalance_formula_row/xeno_abiliter
	statistic_type = BALANCE_FORMULA_XENO_ABILITER

/datum/autobalance_formula_row/xeno_abiliter/formula_calculate(mob/calculationg_mob, datum/player_entity/entity, list/stats = list())
	var/final_calculations = 0
	var/abilities = 0
	var/rounds = 0
	for(var/potential_stat in stats)
		switch(potential_stat)
			if(STATISTICS_ABILITES)
				abilities += stats[potential_stat]
			if(STATISTICS_ROUNDS_PLAYED)
				rounds += stats[potential_stat]

	if(abilities)
		final_calculations += abilities / rounds
	return final_calculations

/datum/autobalance_row_info
	var/rating = 0
	var/active = 3
	var/client/client
	var/datum/player_entity/player

/datum/autobalance_row_info/New(client/client_to_set, datum/player_entity/entity_to_set)
	..()
	client = client_to_set
	player = entity_to_set

/datum/autobalance_row_info/proc/get_player_rating()
	rating = 0
	var/datum/job/player_job = GET_MAPPED_ROLE(client.mob.job)
	for(var/balance_formula in player_job.balance_formulas + client.mob.balance_formulas)
		var/datum/autobalance_formula_row/formula = GLOB.balance_formulas[balance_formula]
		var/additional_rating = formula.calculate(client.mob, player)
		if(additional_rating)
			rating += additional_rating / length(player_job.balance_formulas + client.mob.balance_formulas)
	return rating

/datum/autobalance_row_info/proc/faction_to_set()
	if(client && client.mob)
		return client.mob.faction
	return FALSE

/datum/autobalance_row_info/proc/status_change(action)
	switch(action)
		if("login")
			active = 3
		if("logout")
			active = 2
		if("death")
			active = 1
		if("revive")
			if(client.mob.client)
				active = 3
			else
				active = 2