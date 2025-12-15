using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

using { SBI_VerseUtility }

# Global Environment Generation Data
var GlobalEnvironmentGenerationData : weak_map(session, sbi_environment_generation_data) = map{}

# Get Global Environment Generation Data
GetGlobalEnvGenData<public>()<transacts>:sbi_environment_generation_data =
    if:
        EnvironmentGenerationDataRef := GlobalEnvironmentGenerationData[GetSession()]
        EnvironmentGenerationDataRef.Compiled?
    then:
        EnvironmentGenerationDataRef
    else:
        Print("ERROR: Global Environment Generation Data Reference NOT INITIALIZED.")
        Err("Global Environment Generation Data Reference NOT INITIALIZED.")

# Get Chunk Coordinates with a Vector3
GetChunkCoordinates<public>(V3 : vector3)<transacts><decides>:vector2i = 
    HalfChunkSize := (GetGlobalEnvGenData().ChunkSizeWorldUnits / 2.0).ToV3(?Z := 0.0)
    # RetVal := vector2i:
    #     X := Int[(V3.X + HalfChunkSize.X) / GetGlobalEnvGenData().ChunkSizeWorldUnits.X]
    #     Y := Int[(V3.Y + HalfChunkSize.Y) / GetGlobalEnvGenData().ChunkSizeWorldUnits.Y]
    # vector2i:
    #     X := V3.X < 0.0 and Ceil[(V3.X - HalfChunkSize.X) / GetGlobalEnvGenData().ChunkSizeWorldUnits.X] or Floor[(V3.X - HalfChunkSize.X) / GetGlobalEnvGenData().ChunkSizeWorldUnits.X]
    #     Y := V3.Y < 0.0 and Ceil[(V3.Y - HalfChunkSize.Y) / GetGlobalEnvGenData().ChunkSizeWorldUnits.Y] or Floor[(V3.Y - HalfChunkSize.Y) / GetGlobalEnvGenData().ChunkSizeWorldUnits.Y]
    vector2i:
        X := Floor[(V3.X + HalfChunkSize.X) / GetGlobalEnvGenData().ChunkSizeWorldUnits.X]
        Y := Floor[(V3.Y + HalfChunkSize.Y) / GetGlobalEnvGenData().ChunkSizeWorldUnits.Y]

# Get Chunk Coordinates with a Vector2
GetChunkCoordinates<public>(V2 : vector2)<transacts><decides>:vector2i =
    GetChunkCoordinates[vector3{X := V2.X, Y := V2.Y}]

# Get Chunk with X and Y grid coordinates
GetChunk<public>(X : int, Y : int)<transacts><decides>:sbi_environment_chunk = 
    GetGlobalEnvGenData().ChunkMap[X][Y]

# Get Chunk Map
GetChunkMap<public>()<transacts><decides>:[int][int]sbi_environment_chunk =
    GetGlobalEnvGenData().ChunkMap

    