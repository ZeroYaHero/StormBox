using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }

using { SBI_Rewards }
using { SBI_VerseUtility }

# Configurations for how the Storm Box behaves.
storm_box_data<public> := class<concrete>():
    # Move time, how long it takes for the storm to get from phase A to phase B.
    @editable       MoveTime<public> : float = 60.0
    # Wait time, how long the storm should wait before moving again.
    @editable       WaitTime<public> : float = 10.0
    # Tick time, how long the storm should wait before another tick.
    @editable       TickTime : float = 1.0
    # Tick Damage Amount
    @editable       TickDamageAmount : float = 10.0
    # Safe XYZ Centered
    @editable       Extents<public> : vector3 = vector3{X := 2560.0, Y := 2560.0, Z := 1440.0}
    # Storm Boundaries.
    @editable       var Boundaries : sbi_boundaries = sbi_boundaries:
        Minimum := vector3{X := -30000.0, Y := -30000.0, Z := 768.0}
        Maximum := vector3{X := 30000.0, Y := 30000.0, Z := 5120.0}
    # XY Distance from Terrain Max/Min Coords
    @editable       XYDistanceFromTerrainMaxMin : float = 7680.0
    # Minimum distance the storm can travel for all axises.
    @editable       MinDistance : vector3 = vector3{X := 7680.0, Y := 7680.0, Z := 1152.0} # old 5120.0, 5120.0, 2304.0
    # Maximum distance the storm can travel for all axises.
    @editable       MaxDistance : vector3 = vector3{X := 10240.0, Y := 10240.0, Z := 4096.0} # old 7680.0, 7680.0, 5120.0
    # Storm Controller
    @editable       StormDeviceForSFX : advanced_storm_controller_device = advanced_storm_controller_device{}
    # Anti Health
    @editable       AntiHealthPowerup : health_powerup_device = health_powerup_device{}
    # Storm Safety Volume
    @editable       SafeZone : mutator_zone_device = mutator_zone_device{}
    # Storm Prop
    @editable       StormProp<public> : creative_prop = creative_prop{}
    # Post Process Prop
    @editable       PostProcessProp<public> : creative_prop = creative_prop{}
    # Storm SFX BP
    @editable       StormSFX : storm_box_sfx = storm_box_sfx{}
    # Rain VFX Add
    @editable       RainVFXAdd : visual_effect_powerup_device = visual_effect_powerup_device{}
    # Rain VFX remove
    @editable       RainVFXRemove : visual_effect_powerup_device = visual_effect_powerup_device{}
    # Clears the Colors for all Storm Box Faces
    @editable       ClearCine : cinematic_sequence_device = cinematic_sequence_device{}
    # Axises normal direction with Storm Directional Color Cinematic
    @editable       Axises : []storm_box_axis = array:
        XPos : storm_box_axis = storm_box_axis{NormalDirection := vector3{X := 1.0}}
        XNeg : storm_box_axis = storm_box_axis{NormalDirection := vector3{X := -1.0}}
        YPos : storm_box_axis = storm_box_axis{NormalDirection := vector3{Y := 1.0}}
        YNeg : storm_box_axis = storm_box_axis{NormalDirection := vector3{Y := -1.0}}
        ZPos : storm_box_axis = storm_box_axis{NormalDirection := vector3{Z := 1.0}}
        ZNeg : storm_box_axis = storm_box_axis{NormalDirection := vector3{Z := -1.0}}
    # Build Clear Explosive Range
    @editable       BuildClearExplosiveRadius : float = 2560.0
    # Sky Teleporter
    @editable       SkyTeleporter : teleporter_device = teleporter_device{}
    # Sky Teleport Timer
    @editable       SkyTeleportTimer : timer_device = timer_device{}
    # Sky Invulnerability Time
    @editable       SkyInvulnerabilityTime : float = 5.0
    # Sky Teleporter Distance From Max Z
    @editable       SkyTeleporterDistanceFromMaxZ : float = 3840.0
    # Use Debug
    @editable       UseDebug<public> : logic = false