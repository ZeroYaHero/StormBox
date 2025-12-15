using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }

using { SBI_Objects.SBI_SpawnGeneration }
using { SBI_Objects.SBI_EnvironmentGeneration }

# SBI Grid Point
sbi_grid_point<public> := class<unique>:

    # Occupied Count
    var OccupiedCount<public> : int = 0
    # Maybe Player Spawn
    var SpawnPresent<public> : logic = false
    # Material Piece
    var MaybeSpawnedMaterialPiece<public> : ?sbi_spawned_material_piece = false
    # Maybe POI
    var MaybePOI<public> : ?sbi_simple_poi = false
    # Location
    Location<public> : vector3 = vector3{}
    # PointType
    var <private>PointType<public> : sbi_grid_point_type = sbi_grid_point_type.Unoccupied

    # Add Terrain
    AddTerrain<public>(PointTypeToAdd : sbi_grid_point_type):void =
        set OccupiedCount += 1
        if(PointType <> PointTypeToAdd):
            ResolvePointConflict(PointTypeToAdd)
            if(GetPointType() <> sbi_grid_point_type.Ground, SpawnedMaterialPiece := MaybeSpawnedMaterialPiece?):
                SpawnedMaterialPiece.Invalidate()
                set MaybeSpawnedMaterialPiece = false

    # Add MaybePlayerSpawn
    AddSpawn<public>():void =
        set SpawnPresent = true

    # Add POI
    AddPOI<public>(POI : sbi_simple_poi):void =
        set MaybePOI = option{POI}

    # Add Spawned Material
    AddSpawnedMaterialPiece<public>(NewSpawnedMaterialPiece : sbi_spawned_material_piece):void =
        set MaybeSpawnedMaterialPiece = option{NewSpawnedMaterialPiece}

    # Remove MaybePlayerSpawn
    RemoveSpawn<public>():void =
        set SpawnPresent = false
        
    # If this point relative to a piece represents a different point type, resolve conflict.
    ResolvePointConflict<private>(NewPointType : sbi_grid_point_type)<transacts>:void =
        if(GetPointPriority(NewPointType) > GetPointPriority(PointType)):
            set PointType = NewPointType

    # Get Point Type
    GetPointType<public>()<transacts>:sbi_grid_point_type = 
        return PointType

# Get Color of Grid Point
(GridPoint : sbi_grid_point).GetColor():color =
    case(GridPoint.PointType):

        sbi_grid_point_type.Ground =>
            NamedColors.Green
        sbi_grid_point_type.Surface =>
            NamedColors.Purple
        sbi_grid_point_type.Edge =>
            NamedColors.Yellow
        sbi_grid_point_type.Hidden =>
            NamedColors.Red
        _ =>
            NamedColors.Blue

# Grid Point Type
sbi_grid_point_type<public> := enum:
    Hidden # Red
    Material # Material
    Edge # Edge possibly prevent terrain that is just sharing ground?
    Ground # Green
    Surface # Purple
    Unoccupied # Any point not shown

# Ranked in terms of how "important" these are
GetPointPriority(PointTypeToGet : sbi_grid_point_type)<transacts>:int =
    case(PointTypeToGet):      
        sbi_grid_point_type.Hidden =>            # Absolutely nothing can go here
            return 7
        sbi_grid_point_type.Material =>
            return 6
        sbi_grid_point_type.Edge =>              # Only Islands can go here
            return 5
        sbi_grid_point_type.Ground =>            # MaybePlayerSpawn or Materials can go here
            return 3
        sbi_grid_point_type.Surface =>           # MaybePlayerSpawn can go here
            return 2
        sbi_grid_point_type.Unoccupied =>        # Anything can go here, it is empty
            return 1

# Grid Point Type To String
ToString<public>(PointType : sbi_grid_point_type):string = 
    case(PointType):
        sbi_grid_point_type.Hidden =>
            return "Hidden"
        sbi_grid_point_type.Material =>
            return "Material"
        sbi_grid_point_type.Edge =>
            return "Edge"
        sbi_grid_point_type.Ground =>
            return "Ground"
        sbi_grid_point_type.Surface =>
            return "Surface"
        sbi_grid_point_type.Unoccupied =>
            return "Unoccupied"