using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Colors }

using { SBI_StormBoxStorm }
using { SBI_VerseUtility }

# Environment Generator (Manager/Controller)
sbi_environment_generator<public> := class:

    # Environment Generation Data
    EnvironmentGenerationData<public> : sbi_environment_generation_data
    # All Chunks Generated Event
    AllChunksGeneratedEvent : event() = event(){}
    # All the Chunk Builders
    var ChunkBuilders : []sbi_chunk_builder_device = array{}
    # Debug Drawer
    DebugDrawer : debug_draw = debug_draw{}

    # Initialize
    Initialize<public>()<suspends>:void =
        set ChunkBuilders = for:
            Obj : GetCreativeObjectsWithTag(sbi_chunk_builder_tag{})
            ChunkBuilderDevice := sbi_chunk_builder_device[Obj]
        do:
            ChunkBuilderDevice.Wake()
            ChunkBuilderDevice
        if(ChunkBuilders.Length <= 0):
            Print("ERROR: There are no Chunk Builders")
            Err("There are no Chunk Builders")
        Sleep(1.0)
        BuildTerrainFloor()
        Sleep(1.0)
        BuildChunksInRange(vector3{})

    # Build Terrain Floor
    BuildTerrainFloor()<suspends>:void =
        var ChunkFloorTaskIndex : int = 0
        ChunkFloorTasks := for:
            X -> YToChunkMap : GetChunkMap[]
            Y -> Chunk : YToChunkMap
            ChunkBuilder := ChunkBuilders[Mod[ChunkFloorTaskIndex, ChunkBuilders.Length]]
        do:
            SpawnInstaFix(ChunkBuilder.BuildChunkFloor, (Chunk, EnvironmentGenerationData))

        for(ChunkFloorTask : ChunkFloorTasks):
            ChunkFloorTask.Await()
        
        EnvironmentGenerationData.AllChunksFloorGeneratedEvent.Signal()
        Print("Chunk Floor Tasks Finished")

    # Build Chunks In Range
    BuildChunksInRange(Location : vector3)<suspends>:void =
        var ChunkTaskIndex : int = 0
        ChunkTasks := for:
            X -> YToChunkMap : GetChunkMap[]
            Y -> Chunk : YToChunkMap
            not Chunk.IsTerrainGenerated?
            DistanceXY(Chunk.CenterLocation, Location) <= EnvironmentGenerationData.ChunkBuildRange
            ChunkBuilder := ChunkBuilders[Mod[ChunkTaskIndex, ChunkBuilders.Length]]
        do:
            set ChunkTaskIndex += 1
            SpawnInstaFix(ChunkBuilder.AddChunkToQueue, Chunk)

        for(ChunkTask : ChunkTasks):
            ChunkTask.Await()

        Print("Chunk Terrain and Material Tasks Finished")

    # RegenerateChunks<public>(StormBoxController : storm_box_controller)<suspends>:void =
    #     var ChunksToRegenerate : []sbi_environment_chunk = array{}
    #     loop:
    #         NextPhase := StormBoxController.StormPhaseSelectedEvent.Await()
    #         Print("HELLO???")
    #         PreviousPhase := StormBoxController.GetPreviousPhase()
    #         CurrentLocation := StormBoxController.GetStormLocation()
    #         var MinimumLocation : vector3 = vector3{}
    #         var MaximumLocation : vector3 = vector3{}
    #         var ChunkPath : []sbi_environment_chunk = array{}

    #         if(not Abs(NextPhase.Axis.NormalDirection).IsEqualTo[vector3{Z := 1.0}]):
    #             if(NextPhase.Location.X > CurrentLocation.X or NextPhase.Location.Y >  CurrentLocation.Y):
    #                 set MinimumLocation = BoxToWorld(CurrentLocation, PreviousPhase.Extents)(0)
    #                 set MaximumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(1)
    #             else:
    #                 set MinimumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(0)
    #                 set MaximumLocation = BoxToWorld(CurrentLocation, PreviousPhase.Extents)(1)
    #         else:
    #             set MinimumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(0)
    #             set MaximumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(1)

    #         if(StormBoxController.StormBoxData.UseDebug?):
    #             MinLocNoZ := vector3{X := MinimumLocation.X, Y := MinimumLocation.Y}
    #             MaxLocNoZ := vector3{X := MaximumLocation.X, Y := MaximumLocation.Y}
    #             DebugDrawer.DrawLine(MinLocNoZ, MinLocNoZ + vector3{Z := 7680.0}, ?Color := NamedColors.Yellow, ?Thickness := 10.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxController.StormBoxData.WaitTime + StormBoxController.StormBoxData.MoveTime)
    #             DebugDrawer.DrawLine(MaxLocNoZ, MaxLocNoZ + vector3{Z := 7680.0}, ?Color := NamedColors.Blue, ?Thickness := 10.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxController.StormBoxData.WaitTime + StormBoxController.StormBoxData.MoveTime)

    #         if(MinimumChunkCoords := GetChunkCoordinates[MinimumLocation]):
    #             Print("MinChunkCoords:{MinimumChunkCoords}")
    #             if(MaximumChunkCoords := GetChunkCoordinates[MaximumLocation]):
    #                 Print("MaxChunkCoords:{MaximumChunkCoords}")
    #                 set ChunkPath = for:
    #                     X := MinimumChunkCoords.X..MaximumChunkCoords.X
    #                     Y := MinimumChunkCoords.Y..MaximumChunkCoords.Y
    #                     CurrentChunk := GetChunk[X, Y]
    #                 do:
    #                     if(StormBoxController.StormBoxData.UseDebug?):
    #                         Location := vector3{X := CurrentChunk.CenterLocation.X, Y := CurrentChunk.CenterLocation.Y, Z := 7680.0}
    #                         DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Grey, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxController.StormBoxData.WaitTime + StormBoxController.StormBoxData.MoveTime)
    #                     CurrentChunk

    #             else if(MinimumChunk := GetChunk[MinimumChunkCoords.X, MinimumChunkCoords.Y]):
    #                 set ChunkPath = array{MinimumChunk}
    #         else if:
    #             MaximumChunkCoords := GetChunkCoordinates[MaximumLocation]
    #             MaximumChunk := GetChunk[MaximumChunkCoords.X, MaximumChunkCoords.Y]
    #         then:
    #             Print("MaxChunkCoords:{MaximumChunkCoords}")
    #             set ChunkPath = array{MaximumChunk}
                
    #         set ChunksToRegenerate = Difference(ChunksToRegenerate, ChunkPath)
    #         for(ChunkToRegenerate : ChunksToRegenerate):
    #             if(StormBoxController.StormBoxData.UseDebug?):
    #                 Location := vector3{X := ChunkToRegenerate.CenterLocation.X, Y := ChunkToRegenerate.CenterLocation.Y, Z := 7680.0}
    #                 DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Green, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxController.StormBoxData.WaitTime + StormBoxController.StormBoxData.MoveTime)
    #             ChunkToRegenerate.RespawnMaterials()

    #         set ChunksToRegenerate = ChunkPath
            # if:
            #     MinimumChunkCoords := GetChunkCoordinates[MinimumLocation]
            #     MaximumChunkCoords := GetChunkCoordinates[MaximumLocation]
            # then:
            #     Print("MinChunkCoords:{MinimumChunkCoords}\nMaxChunkCoords:{MaximumChunkCoords}")
            #     set ChunkPath = for:
            #         X := MinimumChunkCoords.X..MaximumChunkCoords.X
            #         Y := MinimumChunkCoords.Y..MaximumChunkCoords.Y
            #         CurrentChunk := GetChunk[X, Y]
            #     do:
            #         if(StormBoxController.StormBoxData.UseDebug?):
            #             Location := vector3{X := CurrentChunk.CenterLocation.X, Y := CurrentChunk.CenterLocation.Y, Z := 7680.0}
            #             DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Grey, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxController.StormBoxData.WaitTime + StormBoxController.StormBoxData.MoveTime)
            #         CurrentChunk
    
            #     NewChunksToRegenerate := Difference(ChunksToRegenerate, ChunkPath)
            #     for(ChunkToRegenerate : NewChunksToRegenerate):
            #         if(StormBoxController.StormBoxData.UseDebug?):
            #             Location := vector3{X := ChunkToRegenerate.CenterLocation.X, Y := ChunkToRegenerate.CenterLocation.Y, Z := 7680.0}
            #             DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Green, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxController.StormBoxData.WaitTime + StormBoxController.StormBoxData.MoveTime)
            #         ChunkToRegenerate.RespawnMaterials()
    
            #     set ChunksToRegenerate = ChunkPath
            # else:
            #     Print("FAILED TO GET CHUNK COORDS FOR {MinimumLocation} and {MaximumLocation} which are definitley within: {EnvironmentGenerationData.EnvironmentBoundaries}")

