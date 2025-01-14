/datum/entity/donater
	var/player_id
	var/ckey
	var/rank

BSQL_PROTECT_DATUM(/datum/entity/donater)

/datum/entity_meta/donater
	entity_type = /datum/entity/donater
	table_name = "donaters"
	field_types = list(
	"player_id" = DB_FIELDTYPE_BIGINT,
	"ckey" = DB_FIELDTYPE_STRING_MAX,
	"rank" = DB_FIELDTYPE_STRING_MAX,
	)

/datum/view_record/donater_view
	var/ckey
	var/rank

/datum/entity_view_meta/donater_view
	root_record_type = /datum/entity/donater
	destination_entity = /datum/view_record/donater_view
	fields = list(
		"player_id",
		"ckey",
		"rank",
	)
	order_by = list("ckey" = DB_ORDER_BY_DESC)


/datum/entity/skin
	var/player_id
	var/skin_name
	var/skins_db
	var/list/skin = list()

BSQL_PROTECT_DATUM(/datum/entity/skin)

/datum/entity_meta/skin
	entity_type = /datum/entity/skin
	table_name = "players_skins"
	field_types = list(
		"player_id" = DB_FIELDTYPE_BIGINT,
		"skin_name" = DB_FIELDTYPE_STRING_LARGE,
		"skins_db" = DB_FIELDTYPE_STRING_MAX,
	)

/datum/entity_meta/skin/map(datum/entity/skin/ET, list/values)
	..()
	if(values["skins_db"])
		ET.skin = json_decode(values["skins_db"])

/datum/entity_meta/skin/unmap(datum/entity/skin/ET)
	. = ..()
	if(length(ET.skin))
		.["skins_db"] = json_encode(ET.skin)

/proc/patron_tier_decorated(tier)
	if(tier == DONATER_NONE)
		return null

	return "<span class='[tier]'>[tier]</span>"

/datum/donator_info
	var/donator = FALSE
	var/patron_type = DONATER_NONE
	var/datum/entity/player/player_datum
	var/list/skins = list()
	var/list/skins_used = list()

/datum/donator_info/New(datum/entity/player/owner_datum)
	player_datum = owner_datum
	load_info()

/datum/donator_info/proc/load_info()
	DB_FILTER(/datum/entity/skin, DB_COMP("player_id", DB_EQUALS, player_datum.id), CALLBACK(src, TYPE_PROC_REF(/datum/donator_info, load_skins)))

/datum/donator_info/proc/load_skins(list/datum/entity/skin/entity_skins)
	for(var/datum/entity/skin/skin in entity_skins)
		skins[skin.skin_name] = skin

/datum/donator_info/proc/patreon_function_available(required)
	if(GLOB.donaters_functions[patron_type])
		return GLOB.donaters_functions[patron_type][required]
	return FALSE
