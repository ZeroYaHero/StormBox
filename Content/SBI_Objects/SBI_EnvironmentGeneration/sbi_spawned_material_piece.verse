using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }

using { SBI_VerseUtility }

# Generated Piece
sbi_spawned_material_piece<public> := class<unique>():

    PieceUsed<public> : sbi_material_piece

    Transform<public> : transform

    var SpawnedProp<public> : creative_prop

    var InvalidMaterialSpawn : logic = false # ! # TODO # FIXME: Gotta derefernce this so spawned material piece can be thrown to garbage collection

    Respawn(?Force : logic = false):void =
        if(not SpawnedProp.IsValid[]):
            SpawnResult := SpawnProp(PieceUsed.Asset, Transform)
        else if(Force?):
            SpawnedProp.Dispose()
            SpawnResult := SpawnProp(PieceUsed.Asset, Transform)
            if(NewSpawnedProp := SpawnResult(0)?):
                set SpawnedProp = NewSpawnedProp

    # Dispose
    Dispose():void =
        if(SpawnedProp.IsValid[]):
            SpawnedProp.Dispose()

    Invalidate<public>():void =
        set InvalidMaterialSpawn = true
        Dispose()
