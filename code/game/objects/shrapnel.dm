
/proc/create_shrapnel(turf/epicenter, shrapnel_number = 10, shrapnel_direction, shrapnel_spread = 45, datum/ammo/shrapnel_type = /datum/ammo/bullet/shrapnel, datum/cause_data/cause_data, ignore_source_mob = FALSE, on_hit_coefficient = 0.15)
	epicenter = get_turf(epicenter)

	var/initial_angle = 0
	var/angle_increment = 0
	if(shrapnel_direction)
		if(shrapnel_direction in GLOB.alldirs)
			initial_angle = dir2angle(shrapnel_direction) - shrapnel_spread / 2
		else
			initial_angle = shrapnel_direction - shrapnel_spread / 2
		angle_increment = shrapnel_spread * 2 / shrapnel_number
	else
		angle_increment = 360 / shrapnel_number
	var/angle_randomization = angle_increment / 2

	var/mob/living/mob_standing_on_turf
	var/mob/living/mob_lying_on_turf
	var/atom/source = epicenter

	for(var/mob/living/M in epicenter) //find a mob at the epicenter. Non-prone mobs take priority
		if(M.density && !mob_standing_on_turf)
			mob_standing_on_turf = M
		else if(!mob_lying_on_turf)
			mob_lying_on_turf = M

	if(mob_standing_on_turf && isturf(mob_standing_on_turf.loc))
		source = mob_standing_on_turf//we designate any mob standing on the turf as the "source" so that they don't simply get hit by every projectile

	var/mob/source_mob = cause_data?.resolve_mob()
	for(var/i = 0 to shrapnel_number)
		var/obj/item/projectile/projectile = new(epicenter)
		projectile.weapon_cause_data = cause_data
		projectile.firer = cause_data?.resolve_mob()
		projectile.ammo = GLOB.ammo_list[shrapnel_type]
		projectile.bullet_ready_to_fire(source_mob, weapon_source_mob = source_mob)
		if(ignore_source_mob)
			if(mob_standing_on_turf == source_mob)
				projectile.permutated |= mob_standing_on_turf
			else if(mob_lying_on_turf == source_mob)
				projectile.permutated |= mob_lying_on_turf

		var/angle = initial_angle + i*angle_increment + rand(-angle_randomization,angle_randomization)
		projectile.projectile_flags |= PROJECTILE_SHRAPNEL
		projectile.fire_at(null, source_mob, source, projectile.ammo.max_range, projectile.ammo.shell_speed, null, angle)
