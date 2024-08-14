using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Storm box axis.
storm_box_axis<public> := class<concrete>():
    # Cinematic showing the correct face colors.
    @editable       Cine<public> : cinematic_sequence_device = cinematic_sequence_device{}
    # Normal direction.
    @editable       NormalDirection<public> : vector3 = vector3{} # external{}