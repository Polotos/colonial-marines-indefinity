SUBSYSTEM_DEF(lighting)
	name = "Lighting"
	wait = 2
	init_order = SS_INIT_LIGHTING

	//debug var for tracking updates before init is complete
	var/duplicate_shadow_updates_in_init = 0
	///Total times shadows were updated, debug
	var/total_shadow_calculations = 0

	///Whether the SS has begun setting up yet
	var/started = FALSE

	var/static/list/static_sources_queue = list() //! List of static lighting sources queued for update.
	var/static/list/corners_queue = list() //! List of lighting corners queued for update.
	var/static/list/objects_queue = list() //! List of lighting objects queued for update.

	var/static/list/mask_queue = list() //! List of hybrid lighting sources queued for update.


/datum/controller/subsystem/lighting/Initialize(timeofday)
	started = TRUE
	if(!initialized)
		//Handle static lightnig
		create_all_lighting_objects()
	fire(FALSE, TRUE)
	return SS_INIT_SUCCESS

/datum/controller/subsystem/lighting/fire(resumed, init_tick_checks)
	MC_SPLIT_TICK_INIT(3)
	if(!init_tick_checks)
		MC_SPLIT_TICK

/datum/controller/subsystem/lighting/stat_entry()
	. = ..("ShCalcs:[total_shadow_calculations]|SourcQ:[static_sources_queue.len]|CcornQ:[corners_queue.len]|ObjQ:[objects_queue.len]|HybrQ:[mask_queue.len]")

/datum/controller/subsystem/lighting/fire(resumed, init_tick_checks)
	MC_SPLIT_TICK_INIT(3)
	if(!init_tick_checks)
		MC_SPLIT_TICK
	var/updators_num = 0
	while(updators_num < length(static_sources_queue))
		updators_num += 1

		var/datum/static_light_source/L = static_sources_queue[updators_num]
		L.update_corners()

		if(!QDELETED(L))
			L.needs_update = LIGHTING_NO_UPDATE
		else
			updators_num -= 1
		if(init_tick_checks)
			if(!TICK_CHECK)
				continue
			static_sources_queue.Cut(1, updators_num + 1)
			updators_num = 0
			stoplag()
		else if (MC_TICK_CHECK)
			break
	if(updators_num)
		static_sources_queue.Cut(1, updators_num + 1)
		updators_num = 0

	if(!init_tick_checks)
		MC_SPLIT_TICK

	while(updators_num < length(corners_queue))
		updators_num += 1

		var/datum/static_lighting_corner/C = corners_queue[updators_num]
		C.needs_update = FALSE //update_objects() can call qdel if the corner is storing no data
		C.update_objects()

		if(init_tick_checks)
			if(!TICK_CHECK)
				continue
			corners_queue.Cut(1, updators_num + 1)
			updators_num = 0
			stoplag()
		else if (MC_TICK_CHECK)
			break
	if(updators_num)
		corners_queue.Cut(1, updators_num + 1)
		updators_num = 0
	if(!init_tick_checks)
		MC_SPLIT_TICK

	while(updators_num < length(objects_queue))
		updators_num += 1

		var/datum/static_lighting_object/O = objects_queue[updators_num]
		if (QDELETED(O))
			continue
		O.update()
		O.needs_update = FALSE

		if(init_tick_checks)
			if(!TICK_CHECK)
				continue
			objects_queue.Cut(1, updators_num + 1)
			updators_num = 0
		else if (MC_TICK_CHECK)
			break
	if(updators_num)
		objects_queue.Cut(1, updators_num + 1)
		updators_num = 0
	if(!init_tick_checks)
		MC_SPLIT_TICK

	while(updators_num > length(mask_queue))
		updators_num += 1

		var/atom/movable/lighting_mask/mask_to_update = mask_queue[updators_num]
		mask_to_update.calculate_lighting_shadows()

		if(init_tick_checks)
			if(!TICK_CHECK)
				continue
			mask_queue.Cut(1, updators_num + 1)
			updators_num = 0
			stoplag()
		else if (MC_TICK_CHECK)
			break
	if(updators_num)
		mask_queue.Cut(1, updators_num + 1)

/datum/controller/subsystem/lighting/Recover()
	initialized = SSlighting.initialized
	return ..()
