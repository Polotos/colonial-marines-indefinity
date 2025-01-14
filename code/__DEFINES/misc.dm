//for all defines that doesn't fit in any other file.

//Fullscreen overlay resolution in tiles.
#define FULLSCREEN_OVERLAY_RESOLUTION_X 15
#define FULLSCREEN_OVERLAY_RESOLUTION_Y 15

// Droppods
#define DROPPOD_DROPPED (1<<0)
#define DROPPOD_DROPPING (1<<1)
#define DROPPOD_OPEN (1<<2)
#define DROPPOD_STRIPPED (1<<3)
#define DROPPOD_RETURNING (1<<4)

//snow
#define MAX_LAYER_SNOW_LEVELS 3

//dirt type for each turf types.

#define NO_DIRT 0
#define DIRT_TYPE_GROUND 1
#define DIRT_TYPE_MARS 2
#define DIRT_TYPE_SNOW 3
#define DIRT_TYPE_SAND 4
#define DIRT_TYPE_SHALE 5

//wet floors

#define FLOOR_WET_WATER 1
#define FLOOR_WET_ICE 2

// Some defines for smoke spread ranking

#define SMOKE_RANK_HARMLESS 1
#define SMOKE_RANK_LOW 2
#define SMOKE_RANK_MED 3
#define SMOKE_RANK_HIGH 4
#define SMOKE_RANK_BOILER 5
#define SMOKE_RANK_CHLOR 6

// What kind of function to use for Explosions falling off.

#define EXPLOSION_FALLOFF_SHAPE_LINEAR				0
#define EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL			1
#define EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL_HALF	2

#define EXPLOSION_MAX_POWER 5000

#define AREA_AVOID_BIOSCAN			(1<<0)
#define AREA_NOTUNNEL				(1<<1)
#define AREA_ALLOW_XENO_JOIN		(1<<2)
#define AREA_CONTAINMENT			(1<<3)
#define AREA_RECOVER_ITEMS			(1<<5)
#define AREA_RECOVER_FULTON_ITEMS	(1<<6)
#define AREA_RECOVER_CORPSES		(1<<7)
#define AREA_UNWEEDABLE				(1<<8)

/// Default number of ticks for do_after
#define DA_DEFAULT_NUM_TICKS 5

//construction flags

#define CONSTRUCTION_STATE_BEGIN 0
#define CONSTRUCTION_STATE_PROGRESS 1
#define CONSTRUCTION_STATE_FINISHED 2

/// Amount of cells per row/column in grid
#define CELLS 8
/// Size of a cell in pixel
#define CELLSIZE (world.icon_size/CELLS)

// *************************************** //
// DO_AFTER FLAGS
// These flags denote behaviors related to timed actions.
// *************************************** //

// INTERRUPT FLAGS
// These flags define whether specific actions will be interrupted by a given timed action

#define INTERRUPT_NONE 0
#define INTERRUPT_DIFF_LOC (1<<0)

/// Might want to consider adding a separate flag for DIFF_COORDS
#define INTERRUPT_DIFF_TURF (1<<1)
/// Relevant to stat var for mobs
#define INTERRUPT_UNCONSCIOUS (1<<2)

#define INTERRUPT_KNOCKED_DOWN (1<<3)
#define INTERRUPT_STUNNED (1<<4)
#define INTERRUPT_NEEDHAND (1<<5)

/// Allows timed actions to be cancelled upon hitting resist, on by default
#define INTERRUPT_RESIST (1<<6)
/// By default not in INTERRUPT_ALL (too niche)
#define INTERRUPT_DIFF_SELECT_ZONE (1<<7)
/// By default not in INTERRUPT_ALL, should not be used in conjunction with INTERRUPT_DIFF_TURF
#define INTERRUPT_OUT_OF_RANGE (1<<8)
/// By default not in INTERRUPT_ALL (too niche) (Doesn't actually exist.)
#define INTERRUPT_DIFF_INTENT (1<<9)
/// Mainly for boiler globs
#define INTERRUPT_LCLICK (1<<10)

#define INTERRUPT_RCLICK (1<<11)
#define INTERRUPT_SHIFTCLICK (1<<12)
#define INTERRUPT_ALTCLICK (1<<13)
#define INTERRUPT_CTRLCLICK (1<<14)
#define INTERRUPT_MIDDLECLICK (1<<15)
#define INTERRUPT_DAZED (1<<16)
#define INTERRUPT_EMOTE (1<<17)
// By default not in INTERRUPT_ALL (too niche)
#define INTERRUPT_CHANGED_LYING (1<<18)

#define INTERRUPT_ALL    (INTERRUPT_DIFF_LOC|INTERRUPT_DIFF_TURF|INTERRUPT_UNCONSCIOUS|INTERRUPT_KNOCKED_DOWN|INTERRUPT_STUNNED|INTERRUPT_NEEDHAND|INTERRUPT_RESIST)
#define INTERRUPT_ALL_OUT_OF_RANGE  (INTERRUPT_ALL & (~INTERRUPT_DIFF_TURF)|INTERRUPT_OUT_OF_RANGE)
#define INTERRUPT_ALL_OUT_OF_RANGE_WITH_MOVING  (INTERRUPT_ALL_OUT_OF_RANGE & (~INTERRUPT_DIFF_LOC))
#define INTERRUPT_MOVED  (INTERRUPT_DIFF_LOC|INTERRUPT_DIFF_TURF|INTERRUPT_RESIST)
#define INTERRUPT_NO_NEEDHAND    (INTERRUPT_ALL & (~INTERRUPT_NEEDHAND))
#define INTERRUPT_INCAPACITATED  (INTERRUPT_UNCONSCIOUS|INTERRUPT_KNOCKED_DOWN|INTERRUPT_STUNNED|INTERRUPT_RESIST)
#define INTERRUPT_CLICK  (INTERRUPT_LCLICK|INTERRUPT_RCLICK|INTERRUPT_SHIFTCLICK|INTERRUPT_ALTCLICK|INTERRUPT_CTRLCLICK|INTERRUPT_MIDDLECLICK|INTERRUPT_RESIST)

// BEHAVIOR FLAGS
// These flags describe behaviors related to a given timed action.
// These behaviors are either of the person performing the action or any targets.

/// You cannot move the person while this action is being performed
#define BEHAVIOR_IMMOBILE (1<<19)

// *************************************** //
//    END DO_AFTER FLAGS //
// *************************************** //

// MATERIALS

#define MATERIAL_METAL "metal"
#define MATERIAL_PLASTEEL "plasteel"
#define MATERIAL_WOOD "wood plank"
#define MATERIAL_CRYSTAL "plasmagas"

// SIZES FOR ITEMS, use it for w_class

/// Helmets
#define SIZE_TINY 1
/// Armor, pouch slots/pockets
#define SIZE_SMALL 2
/// Backpacks, belts. Size of pistols, general magazines
#define SIZE_MEDIUM 3
/// Size of rifles, SMGs
#define SIZE_LARGE 4
/// Using Large does the same job
#define SIZE_HUGE 5

#define SIZE_MASSIVE 6

// Stack amounts
#define STACK_5 5
#define STACK_10 10
#define STACK_20 20
#define STACK_25 25
#define STACK_30 30
#define STACK_35 35
#define STACK_40 40
#define STACK_45 45
#define STACK_50 50

// Assembly Stages
#define ASSEMBLY_EMPTY 0
#define ASSEMBLY_UNLOCKED 1
#define ASSEMBLY_LOCKED 2

// Matrix CAS Upgrades
#define MATRIX_DEFAULT 0
#define MATRIX_NVG 1
#define MATRIX_WIDE 2

//Multiplier for turning points into cash
#define SUPPLY_TO_MONEY_MUPLTIPLIER 100

//Force the config directory to be something other than "config"
#define OVERRIDE_CONFIG_DIRECTORY_PARAMETER "config-directory"


// These guns can be used at maximum efficacy by untrained civilians.
#define UNTRAINED_USABLE_CATEGORIES list(GUN_CATEGORY_HANDGUN, GUN_CATEGORY_SMG)

/**
 * Get the ultimate area of `A`, similarly to [get_turf].
 *
 * Use instead of `A.loc.loc`.
 */
#define get_area(A) (isarea(A) ? A : get_step(A, 0)?.loc)

//https://secure.byond.com/docs/ref/info.html#/atom/var/mouse_opacity
#define MOUSE_OPACITY_TRANSPARENT 0
#define MOUSE_OPACITY_ICON 1
#define MOUSE_OPACITY_OPAQUE 2

//Misc text define. Does 4 spaces. Used as a makeshift tabulator.
#define FOURSPACES "&nbsp;&nbsp;&nbsp;&nbsp;"

#define CLIENT_FROM_VAR(I) (ismob(I) ? I:client : (istype(I, /client) ? I : (istype(I, /datum/mind) ? I:current?:client : null)))

#define to_chat_forced(Target, Message) to_chat(Target, Message, immediate = TRUE)

#define to_world(Message) to_chat(world, Message)

//world/proc/shelleo
#define SHELLEO_ERRORLEVEL 1
#define SHELLEO_STDOUT 2
#define SHELLEO_STDERR 3

// Shuttles
#define isshuttleturf(T) (length(T.baseturfs) && (/turf/baseturf_skipover/shuttle in T.baseturfs))

//Luma coefficients suggested for HDTVs. If you change these, make sure they add up to 1.
#define LUMA_R 0.213
#define LUMA_G 0.715
#define LUMA_B 0.072

//Automatic punctuation
#define ENDING_PUNCT list(".", "-", "?", "!")

//ghost vision mode pref settings
#define GHOST_VISION_LEVEL_NO_NVG "No Night Vision"
#define GHOST_VISION_LEVEL_MID_NVG "Half Night Vision"
#define GHOST_VISION_LEVEL_FULL_NVG "Full Night Vision"

//Ghost orbit types:
#define GHOST_ORBIT_CIRCLE "circular"
#define GHOST_ORBIT_TRIANGLE "triangular"
#define GHOST_ORBIT_HEXAGON "hexagonal"
#define GHOST_ORBIT_SQUARE "square"
#define GHOST_ORBIT_PENTAGON "pentagonal"

#define COLOR_WEBHOOK_DEFAULT 0x8bbbd5

//Command message cooldown defines:
#define COOLDOWN_COMM_MESSAGE		30 SECONDS
#define COOLDOWN_COMM_MESSAGE_LONG	1 MINUTES
#define COOLDOWN_COMM_REQUEST		5 MINUTES
#define COOLDOWN_COMM_CENTRAL		30 SECONDS
#define COOLDOWN_COMM_DESTRUCT		5 MINUTES

///Cooldown for pred recharge
#define COOLDOWN_BRACER_CHARGE 3 MINUTES

// magic value to use for indicating a proc slept
#define PROC_RETURN_SLEEP -1

//Defines for echo list index positions.
//ECHO_DIRECT and ECHO_ROOM are the only two that actually appear to do anything, and represent the dry and wet channels of the environment effects, respectively.
//The rest of the defines are there primarily for the sake of completeness. It might be worth testing on EAX-enabled hardware, and on future BYOND versions (I've tested with 511, 512, and 513)
#define ECHO_DIRECT 1
#define ECHO_DIRECTHF 2
#define ECHO_ROOM 3
#define ECHO_ROOMHF 4
#define ECHO_OBSTRUCTION 5
#define ECHO_OBSTRUCTIONLFRATIO 6
#define ECHO_OCCLUSION 7
#define ECHO_OCCLUSIONLFRATIO 8
#define ECHO_OCCLUSIONROOMRATIO 9
#define ECHO_OCCLUSIONDIRECTRATIO 10
#define ECHO_EXCLUSION 11
#define ECHO_EXCLUSIONLFRATIO 12
#define ECHO_OUTSIDEVOLUMEHF 13
#define ECHO_DOPPLERFACTOR 14
#define ECHO_ROLLOFFFACTOR 15
#define ECHO_ROOMROLLOFFFACTOR 16
#define ECHO_AIRABSORPTIONFACTOR 17
#define ECHO_FLAGS 18

//Defines for controlling how zsound sounds.
#define ZSOUND_DRYLOSS_PER_Z -2000
#define ZSOUND_DISTANCE_PER_Z 2

#define DEBRIS_SPARKS "spark"
#define DEBRIS_WOOD "wood"
#define DEBRIS_ROCK "rock"
#define DEBRIS_GLASS "glass"
#define DEBRIS_LEAF "leaf"
#define DEBRIS_SNOW "snow"

///Floors inverse-masking frills.
#define FRILL_FLOOR_CUT "frill floor cut"
///Game plane inverse-masking frills.
#define FRILL_GAME_CUT "frill game cut"

#define FRILL_MOB_MASK "frill mob mask"
