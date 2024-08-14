using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }

# This could inherit from a class `sbi_environment_piece`
# Terrain Piece
sbi_terrain_piece<public> := class<concrete>:
    # Asset Used
    @editable       Asset : creative_prop_asset = DefaultCreativePropAsset # For when materials are editable
    # Positive Weighting for Random Selection
    @editable       Weighting : float = 1.0
    # Ground Safe (for Materials) Measurement in UU/CM
    @editable       InitialGroundSafeFromOrigin : float = 1024.0
    # Scale Ratio
    @editable       IntendedScaleRatio : vector3 = vector3{X := 1.0, Y := 1.0, Z := 0.75}
    # Initial Unit Size at Scale:1,1,1
    @editable       InitialSize : vector3 = vector3{}
    # Minimum Scale Multiplier
    @editable       MinimumScaleMultiplier : float = 0.8
    # Maximum Scale Multiplier
    @editable       MaximumScaleMultiplier : float = 1.75 
    # Spawn Offset
    @editable       SpawnOffset : vector3 = vector3{}
    # Bool to use or not
    @editable       Use : logic = true
