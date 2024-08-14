using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Storm Box phase
storm_box_phase<public> := class:
    # Prop representing the storm (may be an empty prop with the mesh attached).
    Prop<public> : creative_prop = creative_prop{}
    # Goal location for this phase.
    Location<public> : vector3 = vector3{}
    # Axis includes normal direction and cinematic sequence.
    Axis<public> : storm_box_axis = storm_box_axis{}
    # Safe XYZ representing, the area that is safe starting from the location.
    Extents<public> : vector3 = vector3{}