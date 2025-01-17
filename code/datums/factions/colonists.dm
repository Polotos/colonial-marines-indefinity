/datum/faction/colonist
	name = NAME_FACTION_COLONIST
	desc = "Colonists, the most ordinary citizens of the colonies, ADDITIONAL INFORMATION IS CHANGED"

	faction_name = FACTION_COLONIST
	faction_iff_tag_type = /obj/item/faction_tag/colonist

	role_mappings = list(
		MODE_NAME_EXTENDED = list(),
		MODE_NAME_DISTRESS_SIGNAL = list(),
		MODE_NAME_FACTION_CLASH = list(),
		MODE_NAME_CRASH = list(),
		MODE_NAME_WISKEY_OUTPOST = list(),
		MODE_NAME_HUNTER_GAMES = list(),
		MODE_NAME_HIVE_WARS = list(),
		MODE_NAME_INFECTION = list()
	)
	roles_list = list(
		MODE_NAME_EXTENDED = ROLES_REGULAR_SURV,
		MODE_NAME_DISTRESS_SIGNAL = ROLES_REGULAR_SURV,
		MODE_NAME_FACTION_CLASH = list(),
		MODE_NAME_CRASH = ROLES_REGULAR_SURV,
		MODE_NAME_WISKEY_OUTPOST = list(),
		MODE_NAME_HUNTER_GAMES = list(
			JOB_SURVIVOR
		),
		MODE_NAME_HIVE_WARS = list(),
		MODE_NAME_INFECTION = list(
			JOB_SURVIVOR
		)
	)

	weight_act = list(
		MODE_NAME_EXTENDED = FALSE,
		MODE_NAME_DISTRESS_SIGNAL = FALSE,
		MODE_NAME_FACTION_CLASH = FALSE,
		MODE_NAME_CRASH = FALSE,
		MODE_NAME_WISKEY_OUTPOST = FALSE,
		MODE_NAME_HUNTER_GAMES = FALSE,
		MODE_NAME_HIVE_WARS = FALSE,
		MODE_NAME_INFECTION = FALSE
	)
