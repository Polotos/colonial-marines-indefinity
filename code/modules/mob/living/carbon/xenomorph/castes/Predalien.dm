/datum/caste_datum/predalien
	caste_type = XENO_CASTE_PREDALIEN
	display_name = "Abomination"

	melee_damage_lower = XENO_DAMAGE_TIER_4
	melee_damage_upper = XENO_DAMAGE_TIER_5
	melee_vehicle_damage = XENO_DAMAGE_TIER_5
	max_health = XENO_HEALTH_TIER_9
	plasma_gain = XENO_PLASMA_GAIN_TIER_9
	plasma_max = XENO_PLASMA_TIER_3
	xeno_explosion_resistance = XENO_EXPLOSIVE_ARMOR_TIER_10
	armor_deflection = XENO_ARMOR_TIER_3
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_TIER_7

	evolution_allowed = FALSE
	minimum_evolve_time = 0

	tackle_min = 3
	tackle_max = 6
	tacklestrength_min = 6
	tacklestrength_max = 10

	is_intelligent = TRUE
	tier = 1
	attack_delay = -2
	can_be_queen_healed = FALSE

	behavior_delegate_type = /datum/behavior_delegate/predalien_base

/mob/living/carbon/xenomorph/predalien
	caste_type = XENO_CASTE_PREDALIEN
	name = "Abomination" //snowflake name
	desc = "A strange looking creature with fleshy strands on its head. It appears like a mixture of armor and flesh, smooth, but well carapaced."
	icon = 'icons/mob/xenos/predalien.dmi'
	icon_state = "Predalien Walking"
	speaking_noise = 'sound/voice/predalien_click.ogg'
	plasma_types = list(PLASMA_CATECHOLAMINE)
	wall_smash = TRUE
	pixel_x = -16
	old_x = -16
	mob_size = MOB_SIZE_BIG
	tier = 1
	age = XENO_NO_AGE //Predaliens are already in their ultimate form, they don't get even better
	show_age_prefix = FALSE
	small_explosives_stun = FALSE

	base_actions = list(
		/datum/action/xeno_action/onclick/xeno_resting,
		/datum/action/xeno_action/onclick/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/activable/tail_stab,
		/datum/action/xeno_action/activable/pounce/predalien,
		/datum/action/xeno_action/onclick/predalien_roar,
		/datum/action/xeno_action/onclick/smash,
		/datum/action/xeno_action/activable/devastate,
		/datum/action/xeno_action/onclick/tacmap,
	)
	mutation_type = "Normal"

	var/butcher_time = 6 SECONDS

	icon_xeno = 'icons/mob/xenos/predalien.dmi'
	icon_xenonid = 'icons/mob/xenonids/predalien.dmi'

	balance_formulas = list(BALANCE_FORMULA_XENO_ABILITER, BALANCE_FORMULA_XENO_FIGHTER)

/mob/living/carbon/xenomorph/predalien/Initialize(mapload, mob/living/carbon/xenomorph/old_xeno, datum/faction/hive_to_set)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(announce_spawn)), 3 SECONDS)
	hunter_data.dishonored = TRUE
	hunter_data.dishonored_reason = "An abomination upon the honor of us all!"
	hunter_data.dishonored_set = src
	hud_set_hunter()

	AddComponent(/datum/component/footstep, FOOTSTEP_XENO_MEDIUM)

/mob/living/carbon/xenomorph/predalien/proc/announce_spawn()
	if(!loc)
		return FALSE

	to_chat(src, {"
<span class='role_body'>|______________________|</span>
<span class='role_header'>You are a predator-alien hybrid!</span>
<span class='role_body'>You are a very powerful xenomorph creature that was born of a Yautja warrior body.
You are stronger, faster, and smarter than a regular xenomorph, but you must still listen to the queen.
You have a degree of freedom to where you can hunt and claim the heads of the hive's enemies, so check your verbs.
Your health meter will not regenerate normally, so kill and die for the hive!</span>
<span class='role_body'>|______________________|</span>
"})
	emote("roar")

/datum/behavior_delegate/predalien_base
	name = "Base Predalien Behavior Delegate"

	var/kills = 0
	var/max_kills = 20

/datum/behavior_delegate/predalien_base/append_to_stat()
	. = list()
	. += "Kills: [kills]/[max_kills]"

/datum/behavior_delegate/predalien_base/on_kill_mob(mob/M)
	. = ..()

	kills = min(kills + 1, max_kills)

/datum/behavior_delegate/predalien_base/melee_attack_modify_damage(original_damage, mob/living/carbon/attacked_mob)
	if(ishuman(attacked_mob))
		var/mob/living/carbon/human/attacked_human = attacked_mob
		if(isspeciesyautja(attacked_human))
			original_damage *= 1.5

	return original_damage + kills * 2.5

/datum/behavior_delegate/predalien_base/handle_slash(mob/victim)
	if(bound_xeno.can_not_harm(victim))
		return FALSE

	var/mob/living/carbon/xenomorph/predalien/xeno = bound_xeno

	if(!istype(xeno))
		return FALSE

	if(victim.stat == DEAD && isxeno_human(victim))
		if(xeno.action_busy)
			to_chat(xeno, SPAN_XENONOTICE("You are already performing an action!"))
			return TRUE

		playsound(xeno.loc, 'sound/weapons/slice.ogg', 25)
		xeno_attack_delay(xeno)

		if(!do_after(xeno, xeno.butcher_time, INTERRUPT_ALL, BUSY_ICON_HOSTILE, victim))
			to_chat(xeno, SPAN_XENONOTICE("You decide not to butcher [victim]"))
			return TRUE

		if(ishuman(victim) && !isworkingjoe(victim)) //No joe meat, can still gib it though
			var/mob/living/carbon/human/human_victim = victim

			var/flesh_type = /obj/item/reagent_container/food/snacks/meat
			var/flesh = "meat"
			if(issynth(human_victim))
				flesh_type = /obj/item/reagent_container/food/snacks/meat/synthmeat/synthflesh
				flesh = "synthetic flesh"
			for(var/i in 1 to 3)
				var/obj/item/reagent_container/food/snacks/meat/new_meat = new flesh_type(human_victim.loc)
				new_meat.name = "[human_victim.name] [flesh]"
				

		else if(isxeno(victim))
			var/mob/living/carbon/xenomorph/xeno_victim = victim

			new /obj/effect/decal/remains/xeno(xeno_victim.loc)
			var/obj/item/stack/sheet/animalhide/xeno/xenohide = new /obj/item/stack/sheet/animalhide/xeno(xeno_victim.loc)
			xenohide.name = "[xeno_victim.age_prefix][xeno_victim.caste_type]-hide"
			xenohide.singular_name = "[xeno_victim.age_prefix][xeno_victim.caste_type]-hide"
			xenohide.stack_id = "[xeno_victim.age_prefix][xeno_victim.caste_type]-hide"

		playsound(xeno.loc, 'sound/effects/blobattack.ogg', 25)

		victim.gib(create_cause_data("butchering", xeno))

		return TRUE

	return FALSE
