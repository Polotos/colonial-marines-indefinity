/obj/item/ammo_magazine/hardpoint/flare_launcher
	name = "M-87F Flare Launcher Magazine"
	desc = "A support armament grenade magazine. This one is loaded with flares packaged in expendable shells."
	caliber = "flare"
	icon_state = "slauncher_1"
	w_class = SIZE_LARGE
	ammo_preset = list(/datum/ammo/flare)
	max_rounds = 10
	gun_type = /obj/item/hardpoint/support/flare_launcher

/obj/item/ammo_magazine/hardpoint/flare_launcher/update_icon()
	icon_state = "slauncher_[ammo_position <= 0 ? "0" : "1"]"
