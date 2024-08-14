using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

# Boundary Encapsulation
sbi_boundaries<public> := class<concrete>:

    @editable       IgnoreZAxis<public> : logic = false

    @editable       var Minimum<public> : vector3 = vector3{}

    @editable       var Maximum<public> : vector3 = vector3{}

    WithinBounds<public>(Location : vector3)<transacts><decides>:void =
        Location.X >= Minimum.X
        Location.Y >= Minimum.Y
        Location.X <= Maximum.X
        Location.Y <= Maximum.Y
        if(not IgnoreZAxis?):
            Location.Z >= Minimum.Z
            Location.Z <= Maximum.Z

    WithinBounds<public>(Location : vector2)<transacts><decides>:void =
        Location.X >= Minimum.X
        Location.Y >= Minimum.Y
        Location.X <= Maximum.X
        Location.Y <= Maximum.Y

# Boundaries ToString
ToString<public>(Boundaries : sbi_boundaries)<transacts>:string =
    return "\nMinimum:{Boundaries.Minimum}\nMaximum:{Boundaries.Maximum}"