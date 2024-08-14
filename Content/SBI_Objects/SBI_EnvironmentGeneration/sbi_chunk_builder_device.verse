using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Colors }

using { SBI_VerseUtility }

sbi_chunk_builder_tag := class(tag){}
sbi_chunk_builder_device := class(creative_device):

    ChunkQueue<public> : chunk_queue = chunk_queue{}

    ChunkQueuedEvent<public> : event() = event(){}

    ChunkFinished<private> : event(sbi_environment_chunk) = event(sbi_environment_chunk){}

    DebugDrawer : debug_draw = debug_draw{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        Print("Hi, I'm Chunk Builder Awaiting Instruction :-)")

    # Initialize
    Wake():void =
        spawn { ProcessChunkQueue() }

    # Add Chunk To Queue
    AddChunkToQueue(Chunk : sbi_environment_chunk)<suspends>:void =
        ChunkQueue.Offer(Chunk)
        ChunkQueuedEvent.Signal()
        sync:
            Chunk.TerrainGeneratedEvent.Await()
            Chunk.MaterialGeneratedEvent.Await()

    # Process Chunk Queue
    ProcessChunkQueue<private>()<suspends>:void =
        GlobalEnvGenData := GetGlobalEnvGenData()
        race:
            GlobalEnvGenData.AllChunksGeneratedEvent.Await()
            loop:
                ChunkQueuedEvent.Await()
                loop:
                    if:
                        not ChunkQueue.IsEmpty[]
                        PolledChunk := ChunkQueue.Poll[]
                    then:
                        SpawnInstaFix(BuildChunk, (PolledChunk, GlobalEnvGenData))
                    else:
                        break

    # Build Chunk
    BuildChunk(Chunk : sbi_environment_chunk, EnvGenData : sbi_environment_generation_data)<suspends>:void =
        BuildChunkTerrain(Chunk, EnvGenData)
        BuildChunkMaterialAndPOI(Chunk, EnvGenData)
        EnvGenData.GlobalChunkGeneratedEvent.Signal(Chunk)

    # Build Chunk Floor
    BuildChunkFloor(Chunk : sbi_environment_chunk, EnvGenData : sbi_environment_generation_data)<suspends>:void =
        StartingChunkPoint := vector3:
            X := Chunk.StartLocation.X
            Y := Chunk.StartLocation.Y
            Z := -384.0
        for:
            X := 0..Int[EnvGenData.ChunkDivisionCount.X / 2.0] - 1
            Y := 0..Int[EnvGenData.ChunkDivisionCount.Y / 2.0] - 1
        do:
            AwaitServerTicks(4)
            TerrainPieceOrigin := StartingChunkPoint + (vector3{X := X * 1.0, Y := Y * 1.0} * vector3{X := EnvGenData.ChunkDivisionSize.X * 3.0, Y := EnvGenData.ChunkDivisionSize.Y * 3.0})
            RandomScale := GetRandomFloat(2.0, 3.0)
            GridTerrainPieceTransform := transform:
                Translation := TerrainPieceOrigin
                Rotation := MakeRotationFromYawPitchRollDegrees(GetRandomFloat(0.0, 360.0), 0.0, 0.0)
                Scale := vector3{X := RandomScale, Y := RandomScale, Z := RandomScale}
            MaterialSpawnPropResult := SpawnProp(EnvGenData.TerrainFloorPiece, GridTerrainPieceTransform)
            if(SpawnedProp := MaterialSpawnPropResult(0)?):
                if(Biome := GetBiome(TerrainPieceOrigin, EnvGenData)?):
                    SpawnedProp.SetMaterial(Biome.TerrainMaterial)
                else:
                    Print("WARNING: Failed to get Biome for {TerrainPieceOrigin}")
            else:
                Print("WARNING: Failed to Spawn Terrain Prop due to {MaterialSpawnPropResult(1)}")
    
    # Build Chunk Terrain
    BuildChunkTerrain(Chunk : sbi_environment_chunk, EnvGenData : sbi_environment_generation_data)<suspends>:void =
        set Chunk.IsTerrainGenerated = true
        for(Layer : EnvGenData.Layers):
            StartingChunkPoint := vector3:
                X := Chunk.StartLocation.X
                Y := Chunk.StartLocation.Y
                Z := Layer.XYZCoordinateOffset.Z
            for(X := 0..Int[EnvGenData.ChunkDivisionCount.X] - 1, Y := 0..Int[EnvGenData.ChunkDivisionCount.Y] - 1):
                AwaitServerTicks(3)
                TerrainPieceOrigin := StartingChunkPoint + (vector3{X := X * 1.0, Y := Y * 1.0} * vector3{X := EnvGenData.ChunkDivisionSize.X, Y := EnvGenData.ChunkDivisionSize.Y})
                NoiseValue := EnvGenData.TerrainPerlinNoise.FractalBrownianMotion2D(TerrainPieceOrigin.X + Layer.XYZCoordinateOffset.X, TerrainPieceOrigin.Y + Layer.XYZCoordinateOffset.Y)
                NoiseValueRemapped := Remap(NoiseValue, -1.0, 1.0, 0.0, 1.0)
                if(NoiseValueRemapped <= Layer.TerrainNoiseThreshold):
                    if(RandomTerrainPiece := GetTerrainPiece(EnvGenData.TerrainPiecePrototypes, EnvGenData.TerrainPieceWeightSum)?):

                        RandomScale := GetRandomFloat(RandomTerrainPiece.MinimumScaleMultiplier, RandomTerrainPiece.MaximumScaleMultiplier)

                        # ? # TODO: This should be in terrain piece
                        GridTerrainPieceTransform := transform:
                            Translation := TerrainPieceOrigin + GetZTileOffsetAlt(NoiseValueRemapped, Layer.TerrainNoiseThreshold, EnvGenData)
                            Rotation := MakeRotationFromYawPitchRollDegrees(GetRandomFloat(0.0, 360.0), 0.0, 0.0)
                            Scale := RandomScale * RandomTerrainPiece.IntendedScaleRatio

                        OffsetTerrainPieceTransform := transform:
                            Translation := GridTerrainPieceTransform.Translation + RandomTerrainPiece.SpawnOffset
                            Rotation := GridTerrainPieceTransform.Rotation
                            Scale := GridTerrainPieceTransform.Scale

                        TerrainSpawnPropResult := SpawnProp(RandomTerrainPiece.Asset, OffsetTerrainPieceTransform)

                        if(EnvGenData.ShowIslandBoundingBox?):
                            DebugPoint := vector3{X := GridTerrainPieceTransform.Translation.X, Y := GridTerrainPieceTransform.Translation.Y, Z := GridTerrainPieceTransform.Translation.Z - ((RandomTerrainPiece.InitialSize.Z * GridTerrainPieceTransform.Scale.Z) / 2.0)}
                            DebugExtent := (RandomTerrainPiece.InitialSize * GridTerrainPieceTransform.Scale) / 2.0
                            DebugDrawer.DrawBox(DebugPoint, IdentityRotation(), ?Extent := DebugExtent, ?Color := NamedColors.Yellow, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)

                        if(SpawnedProp := TerrainSpawnPropResult(0)?):
                            if(Biome := GetBiome(TerrainPieceOrigin, EnvGenData)?):
                                SpawnedProp.SetMaterial(Biome.TerrainMaterial)
                                CalculateTerrainOccupyingGridPoints(SpawnedProp, GridTerrainPieceTransform, RandomTerrainPiece, EnvGenData)
                            else:
                                Print("WARNING: Failed to get Biome for {TerrainPieceOrigin}, Disposing to prevent no material.")
                                if(SpawnedProp.IsValid[]):
                                    SpawnedProp.Dispose()
                        else:
                            Print("WARNING: Failed to Spawn Terrain Prop due to {TerrainSpawnPropResult(1)}")

                    # ! THIS IS NEWWWW
                    # if:
                    #     NoiseValueRemapped <= (Layer.TerrainNoiseThreshold * 0.5)
                    #     RandomHillSlopeTerrainPiece := GetTerrainPiece(EnvGenData.HillSlopeTerrainPieces, EnvGenData.HillSlopeTerrainPieceWeightSum)?
                    # then:
                    #     XYScale := GetRandomFloat(RandomHillSlopeTerrainPiece.MinimumScaleMultiplier, RandomHillSlopeTerrainPiece.MaximumScaleMultiplier)
                    #     Scale := vector3{X := XYScale, Y := XYScale, Z := 1.3} 
                    #     HillSlopeTerrainPieceTransform := transform:
                    #         Translation := TerrainPieceOrigin + RandomHillSlopeTerrainPiece.SpawnOffset + vector3{Z := 384.0}
                    #         Rotation := MakeRotationFromYawPitchRollDegrees(GetRandomFloat(0.0, 360.0), 0.0, 0.0)
                    #         Scale := Scale

                    #     HillSlopeSpawnResult := SpawnProp(RandomHillSlopeTerrainPiece.Asset, HillSlopeTerrainPieceTransform)
                    #     if(SpawnedProp := HillSlopeSpawnResult(0)?):
                    #         if(Biome := GetBiome(TerrainPieceOrigin, EnvGenData)?):
                    #             SpawnedProp.SetMaterial(Biome.TerrainMaterial)
                    # ! THIS IS NEWWWW
                            
                    else:
                        Print("WARNING: GetTerrainPiece returned false")
        Chunk.TerrainGeneratedEvent.Signal()

    # Build Chunk Material
    BuildChunkMaterialAndPOI(Chunk : sbi_environment_chunk, EnvGenData : sbi_environment_generation_data)<suspends>:void =
        set Chunk.IsMaterialGenerated = true
        for(Index -> GroundSafeGridPoint : Chunk.GroundSafeGridPoints):
            if(Mod[Index, 8] = 0):
                Sleep(0.0)
            if(MaterialSpawnSafe[GroundSafeGridPoint]):
                if(Biome := GetBiome(GroundSafeGridPoint.Location, EnvGenData)?):
                    RandomMaterialChance := GetRandomFloat(0.0, 1.0)
                    RandomPOIChance := GetRandomFloat(0.0, 1.0)
                    if(RandomMaterialChance < Biome.MaterialProbability):
                        if(RandomMaterial := Biome.GetMaterialPiece()?):
                            RandomMaterial.SpawnMaterial(GroundSafeGridPoint, Chunk)
                        else:
                            Print("WARNING: Failed to get Material Piece for Biome:{Biome.BiomeName}")
                    else if(Biome.POIs.Length > 0, RandomPOIChance < Biome.POIProbability):
                        if(RandomPOI := Biome.GetPOI()?):
                            RandomPOI.PlacePOI(GroundSafeGridPoint)
                        else:
                            Print("WARNING: Failed to get POI for Biome:{Biome.BiomeName}.")
                else:
                    Print("WARNING: Failed to get Biome for {GroundSafeGridPoint.Location}")
        Chunk.MaterialGeneratedEvent.Signal()

    # Calculate Terrain Occupying Grid Points
    CalculateTerrainOccupyingGridPoints(SpawnedProp : creative_prop, SpawnTransform : transform, PieceUsed : sbi_terrain_piece, EnvGenData : sbi_environment_generation_data)<suspends>:void =
        Origin := SpawnTransform.Translation
        Scale := SpawnTransform.Scale
        ScaledSize := Scale * vector3:
            X := Max(PieceUsed.InitialSize.X, PieceUsed.InitialSize.Y)
            Y := Max(PieceUsed.InitialSize.X, PieceUsed.InitialSize.Y)
            Z := PieceUsed.InitialSize.Z
        if:
            GridCountX := Ceil[ScaledSize.X / EnvGenData.GridPointSize.X]
            GridCountY := Ceil[ScaledSize.Y / EnvGenData.GridPointSize.Y]
            GridCountZ := Ceil[ScaledSize.Z / EnvGenData.GridPointSize.Z]
            Offset := vector3:
                X := EnvGenData.GridPointSize.X * Int[(GridCountX * 1.0) / 2.0] # Changed Offset from 512.0 to `EnvGenData.GridPointSize.Axis
                Y := EnvGenData.GridPointSize.Y * Int[(GridCountY * 1.0) / 2.0]
                Z := 0.0
        then:
            StartPoint := Origin - Offset
            for(X := 0..GridCountX, Y := 0..GridCountY, Z := 0..GridCountZ):
                Location : vector3 = StartPoint + vector3:
                    X := EnvGenData.GridPointSize.X * X
                    Y := EnvGenData.GridPointSize.Y * Y
                    Z := EnvGenData.GridPointSize.Z * Z * (-1.0)
                PointType : sbi_grid_point_type = block:
                    var EndType : sbi_grid_point_type = sbi_grid_point_type.Hidden
                    if:
                        X = 0 or 
                        X = GridCountX or
                        Y = 0 or 
                        Y = GridCountY or
                        Z = 0
                    then:
                        set EndType = sbi_grid_point_type.Edge
                        if(Z = 0):
                            set EndType = sbi_grid_point_type.Surface
                            # We have confirmed its "surface" level. Test if Ground.
                            if(Distance(Location, Origin) < PieceUsed.InitialGroundSafeFromOrigin * ((Scale.X + Scale.Y) / 2.0)): # Changed from (Scale.X + Scale.Y + Scale.Z) / 3.0
                                set EndType = sbi_grid_point_type.Ground
                    EndType
                if(ChunkCoordinates := GetChunkCoordinates[Location]):
                    if(Chunk := GetChunk[ChunkCoordinates.X, ChunkCoordinates.Y]):
                        if(CurrentGridPoint := Chunk.GridPoints[(Location.X, Location.Y, Location.Z)]?):
                            CurrentPointType := CurrentGridPoint.PointType
                            CurrentGridPoint.AddTerrain(PointType)
                            NewPointType := CurrentGridPoint.GetPointType()
                            if(CurrentPointType = sbi_grid_point_type.Ground and NewPointType <> sbi_grid_point_type.Ground):
                                set Chunk.GroundSafeGridPoints = Chunk.GroundSafeGridPoints.RemoveAllElements(CurrentGridPoint)
                                if(EnvGenData.ShowGroundSafeGridPoints?):
                                    DebugDrawer.DrawBox(CurrentGridPoint.Location, IdentityRotation(), ?Extent := vector3{X := 128.0, Y := 128.0, Z := 128.0}, ?Color := NamedColors.Red, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                            else if(NewPointType = sbi_grid_point_type.Ground and GetPointPriority(NewPointType) > GetPointPriority(CurrentPointType)):
                                set Chunk.GroundSafeGridPoints += array{CurrentGridPoint}
                                if(EnvGenData.ShowGroundSafeGridPoints?):
                                    DebugDrawer.DrawBox(CurrentGridPoint.Location, IdentityRotation(), ?Extent := vector3{X := 64.0, Y := 64.0, Z := 64.0}, ?Color := NamedColors.Lime, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                        else:
                            NewSharedGridPoint := sbi_grid_point:
                                OccupiedCount := 1
                                Location := Location
                                PointType := PointType
                            if(Chunk.AddGridPoint[NewSharedGridPoint]): # Seperate If statement to prevent rollback
                                if(NewSharedGridPoint.PointType = sbi_grid_point_type.Ground):
                                    set Chunk.GroundSafeGridPoints += array{NewSharedGridPoint}
                                    if(EnvGenData.ShowGroundSafeGridPoints?):
                                        DebugDrawer.DrawBox(NewSharedGridPoint.Location, IdentityRotation(), ?Extent := vector3{X := 128.0, Y := 128.0, Z := 128.0}, ?Color := NamedColors.Red, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                            else:
                                Print("WARNING: GridPoint was not added to Chunk({ChunkCoordinates.X},{ChunkCoordinates.Y})")
                    else:
                        # Print("WARNING: Failed to get Chunk at Coordinates({ChunkCoordinates.X},{ChunkCoordinates.Y})")
                else:
                    Print("WARNING: Failed to get Chunk Coordinates at {Location}")


    # Material Spawn Safe
    MaterialSpawnSafe(GridPoint : sbi_grid_point)<transacts><decides>:void =
        GridPoint.PointType = sbi_grid_point_type.Ground

    # Get Z Tile Offset
    GetZTileOffset(NoiseValue : float, LayerTerrainNoiseThreshold : float, EnvGenData : sbi_environment_generation_data):vector3 =
        Value := Remap(NoiseValue, 0.0, LayerTerrainNoiseThreshold, 0.0, 1.0)

        NegativeInfluence := Value
        PositiveInfluence := 1.0 - Value

        NegativeProbability := NegativeInfluence * EnvGenData.TerrainZOffsetNegativeProbability
        PositiveProbability := PositiveInfluence * EnvGenData.TerrainZOffsetPositiveProbability

        RandomValue := GetRandomFloat(0.0, 1.0)
        
        if(RandomValue < NegativeProbability):
            # return vector3{Z := -384.0}
        else if(RandomValue < (NegativeProbability + PositiveProbability)):
            # return vector3{Z := 384.0}
        return vector3{}

    GetZTileOffsetAlt(NoiseValue : float, LayerTerrainNoiseThreshold : float, EnvGenData : sbi_environment_generation_data):vector3 = 
        Value := Remap(NoiseValue, 0.0, LayerTerrainNoiseThreshold, 0.0, 1.0)

        PositiveProbability := 0.15
        NegativeProbability := 0.15

        # if(Value <= NegativeProbability):
        #     return vector3{Z := 192.0}
        # else if(Value >= (1.0 - PositiveProbability)):
        #     return vector3{Z := -192.0}
        return vector3{}

    # Get Terrain Piece
    # GetTerrainPiece(EnvGenData : sbi_environment_generation_data)<transacts>:?sbi_terrain_piece =
    #     var RandomWeight : float = GetRandomFloat(0.0, EnvGenData.TerrainPieceWeightSum)
    #     for(TerrainPiecePrototype : EnvGenData.TerrainPiecePrototypes, TerrainPiecePrototype.Use?):
    #         if:
    #             RandomWeight < TerrainPiecePrototype.Weighting
    #         then:
    #             return option{TerrainPiecePrototype}
    #         else:
    #             set RandomWeight = (RandomWeight - TerrainPiecePrototype.Weighting)
    #     return false

    GetTerrainPiece(TerrainPieceCollection : []sbi_terrain_piece, WeightSum : float)<transacts>:?sbi_terrain_piece =
        var RandomWeight : float = GetRandomFloat(0.0, WeightSum)
        for(TerrainPiece : TerrainPieceCollection, TerrainPiece.Use?):
            if:
                RandomWeight < TerrainPiece.Weighting
            then:
                return option{TerrainPiece}
            else:
                set RandomWeight = (RandomWeight - TerrainPiece.Weighting)
        return false

    # Get Biome
    GetBiome(V3 : vector3, EnvGenData : sbi_environment_generation_data)<transacts>:?sbi_environment_biome =
        var TemperatureValue : float = GetTemperature(V3, EnvGenData)
        for(TemperateIndex -> TemperateBiome : EnvGenData.TemperateBiomes):
            if(TemperatureValue < TemperateBiome.NormedWeighting or TemperateIndex = EnvGenData.TemperateBiomes.Length -1):
                if(ClosestHumidityPoint := GetClosestHumidityPoint(V3, EnvGenData)?):
                    var HumidityLevel : float = ClosestHumidityPoint.HumidityLevel
                    for(BiomeIndex -> Biome : TemperateBiome.Biomes):
                        if(ClosestHumidityPoint.HumidityLevel < Biome.NormedWeighting or BiomeIndex = TemperateBiome.Biomes.Length -1):
                            return option{Biome}
                        else:
                            set HumidityLevel -= Biome.NormedWeighting
                else:
                    Print("WARNING: Closest humidity point returned false, unexpected behavior will follow!")
            else:
                set TemperatureValue -= TemperateBiome.NormedWeighting
        return false

    # Get Temperature
    GetTemperature(V3 : vector3, EnvGenData : sbi_environment_generation_data)<transacts>:float =
        return Remap(EnvGenData.BiomePerlinNoise.FractalBrownianMotion2D(V3.X, V3.Y), -1.0, 1.0, 0.0, 1.0)

    # Get Closest Humidity Point
    GetClosestHumidityPoint(V3 : vector3, EnvGenData : sbi_environment_generation_data)<transacts>:?sbi_humidity_point =
        var MaybeClosestHumidityPoint : ?sbi_humidity_point = false
        for(HumidityPoint : EnvGenData.HumidityPoints):
            if(ClosestHumidityPoint := MaybeClosestHumidityPoint?):
                if(DistanceXY(HumidityPoint.Location, V3) < DistanceXY(ClosestHumidityPoint.Location, V3)):
                    set MaybeClosestHumidityPoint = option{HumidityPoint}
            else:
                set MaybeClosestHumidityPoint = option{HumidityPoint}

        return MaybeClosestHumidityPoint