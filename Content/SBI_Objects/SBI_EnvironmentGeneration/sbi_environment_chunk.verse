using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

sbi_environment_chunk<public> := class<unique>:

    GridCoordinates<public> : vector2i

    StartLocation<public> : vector3
    
    CenterLocation<public> : vector3 = vector3{}

    var IsTerrainGenerated : logic = false

    TerrainGeneratedEvent : event() = event(){}

    var IsMaterialGenerated : logic = false

    MaterialGeneratedEvent : event() = event(){}

    var GroundSafeGridPoints : []sbi_grid_point = array{}

    var SpawnedMaterialPieces : []sbi_spawned_material_piece = array{}

    var GridPoints : [comparable]?sbi_grid_point = map{}

    GetGridPointAt<public>(Location : vector3)<transacts><decides>:?sbi_grid_point =
        GridPoints[(Location.X, Location.Y, Location.Z)]

    AddGridPoint<public>(GridPoint : sbi_grid_point)<transacts><decides>:void =
        set GridPoints[(GridPoint.Location.X, GridPoint.Location.Y, GridPoint.Location.Z)] = option{GridPoint}

    NullifyGridPoint<public>(GridPoint : sbi_grid_point)<transacts><decides>:void =
        set GridPoints[(GridPoint.Location.X, GridPoint.Location.Y, GridPoint.Location.Z)] = false

    NullifyGridPointAt<public>(Location : vector3)<transacts><decides>:void =
        set GridPoints[(Location.X, Location.Y, Location.Z)] = false

    RespawnMaterials<public>():void =
        for(SpawnedMaterialPiece : SpawnedMaterialPieces):
            SpawnedMaterialPiece.Respawn()