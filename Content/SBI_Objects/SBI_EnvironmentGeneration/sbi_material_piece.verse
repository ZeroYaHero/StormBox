using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }

# This could inherit from a class `sbi_environment_piece`
# Material piece (disposable/destructible)
sbi_material_piece<public> := class<concrete>():
    # Asset used for material
    @editable       Asset : creative_prop_asset = DefaultCreativePropAsset
    # Weighting (positive)
    @editable       Weighting : float = 1.0
    # Minimum Scale Multiplier
    @editable       MinimumScaleMultiplier : float = 0.75
    # Maximum Scale Multiplier
    @editable       MaximumScaleMultiplier : float = 1.0
    # Range
    @editable       SpawnOffsetMaximumRange : float = 64.0

    # Spawn Material Piece
    SpawnMaterial(GroundSafeGridPoint : sbi_grid_point, Chunk : sbi_environment_chunk):void = 
        MaterialRotation := MakeRotationFromYawPitchRollDegrees(GetRandomFloat(0.0, 360.0), 0.0, 0.0)
        Offset := MaterialRotation.GetLocalForward() * GetRandomFloat(0.0, SpawnOffsetMaximumRange)
        Transform := transform:
            Translation := GroundSafeGridPoint.Location - vector3{Z := 32.0} + Offset
            Rotation := MaterialRotation
            Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0} * GetRandomFloat(MinimumScaleMultiplier, MaximumScaleMultiplier)

        MaterialSpawnPropResult := SpawnProp(Asset, Transform)
        if(MaterialSpawnedProp := MaterialSpawnPropResult(0)?):
            SpawnedMaterialPiece := sbi_spawned_material_piece:
                PieceUsed := Self
                Transform := Transform
                SpawnedProp := MaterialSpawnedProp
            set Chunk.SpawnedMaterialPieces += array{SpawnedMaterialPiece}
            GroundSafeGridPoint.AddSpawnedMaterialPiece(SpawnedMaterialPiece)
        else:
            Print("WARNING: Spawn Prop Failed for Material Piece")