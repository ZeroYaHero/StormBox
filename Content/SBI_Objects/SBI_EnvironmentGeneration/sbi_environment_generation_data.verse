using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Fortnite.com/Devices }

using { SBI_Noise }
using { SBI_VerseUtility }

# Environment Generation Categories
sbi_environment_generation_categories := module:

    BiomeParameters<public><localizes>:message = "Biome Parameters"
    LayerParameters<public><localizes>:message = "Layer Parameters"
    TerrainParameters<public><localizes>:message = "Terrain Parameters"
    ChunkAndGridParameters<public><localizes>:message = "Chunk and Grid Parameters"
    DebugParameters<public><localizes>:message = "Debug"

# Environment Generation Data
sbi_environment_generation_data<public> := class<concrete>:

    # Biome Parameters
    @editable:
        Categories:=array{sbi_environment_generation_categories.BiomeParameters}
    BiomePerlinNoiseScale<public> : float = 0.006

    @editable:
        Categories:=array{sbi_environment_generation_categories.BiomeParameters}
    HumidityPointCount<public> : int = 5

    @editable:
        Categories:=array{sbi_environment_generation_categories.BiomeParameters}
    TemperateBiomes<public> : []sbi_temperate_biome_collection = array:
        sbi_temperate_biome_collection:
            TemperateName := "Freezing"
            Weighting := 1.0
            Biomes := array:
                sbi_environment_biome:
                    BiomeName := "TundraTaiga"
                    TerrainMaterial := SBI_BiomeMaterials.MI_TundraTaigaTerrain
        sbi_temperate_biome_collection:
            TemperateName := "Cold"
            Weighting := 2.0
            Biomes := array:
                sbi_environment_biome:
                    BiomeName := "BorealForest"
                    TerrainMaterial := SBI_BiomeMaterials.MI_BorealForestTerrain 
        sbi_temperate_biome_collection:
            TemperateName := "Average"
            Weighting := 3.0
            Biomes := array:
                sbi_environment_biome:
                    BiomeName := "BirchFall"
                    TerrainMaterial := SBI_BiomeMaterials.MI_BirchFallTerrain
                sbi_environment_biome:
                    BiomeName := "OakGreen"
                    TerrainMaterial := SBI_BiomeMaterials.MI_OakGreenTerrain
        sbi_temperate_biome_collection:
            TemperateName := "Warm"
            Weighting := 2.0
            Biomes := array:
                sbi_environment_biome:
                    BiomeName := "Plains"
                    TerrainMaterial := SBI_BiomeMaterials.MI_PlainsTerrain
        sbi_temperate_biome_collection:
            TemperateName := "Hot"
            Weighting := 1.0
            Biomes := array:
                sbi_environment_biome:
                    BiomeName := "Desert"
                    TerrainMaterial := SBI_BiomeMaterials.MI_DesertTerrain
                sbi_environment_biome:
                    BiomeName := "RainForest"
                    TerrainMaterial := SBI_BiomeMaterials.MI_RainForestTerrain

    # Environment Boundaries
    @editable       EnvironmentBoundaries<public> : sbi_boundaries = sbi_boundaries:
        IgnoreZAxis :=  true
        Minimum := vector3{X := -24000.0, Y := -24000.0}
        Maximum := vector3{X := 24000.0, Y := 24000.0}

    # Terrain Settings
    @editable:
        Categories:=array{sbi_environment_generation_categories.TerrainParameters}
    TerrainPiecePrototypes<public> : []sbi_terrain_piece = array{}

    # ! THIS IS NEW (TEMP?)
    # @editable:
    #     Categories:=array{sbi_environment_generation_categories.TerrainParameters}
    # HillSlopeTerrainPieces<public> : []sbi_terrain_piece = array{}
    # ! THIS IS NEW (TEMP?)

    @editable:
        Categories:=array{sbi_environment_generation_categories.TerrainParameters}
    TerrainFloorPiece<public> : creative_prop_asset = DefaultCreativePropAsset

    @editable:
        Categories:=array{sbi_environment_generation_categories.TerrainParameters} 
    TerrainNoiseThreshold<public> : normalized_range = 0.34

    @editable:
        Categories:=array{sbi_environment_generation_categories.TerrainParameters}
    TerrainPerlinNoiseScale<public> : float = 0.031

    @editable:
        Categories:=array{sbi_environment_generation_categories.TerrainParameters}
    TerrainZOffsetPositiveProbability<public> : float = 0.1

    @editable:
        Categories:=array{sbi_environment_generation_categories.TerrainParameters}
    TerrainZOffsetNegativeProbability<public> : float = 0.05

    # Chunk + Grid Parameters
    @editable:
        Categories:=array{sbi_environment_generation_categories.ChunkAndGridParameters}
    ChunkBuildRange<public> : float = Inf

    @editable:
        Categories:=array{sbi_environment_generation_categories.ChunkAndGridParameters}    
    ChunkDivisionCount<public> : vector2 = vector2{X := 8.0, Y := 8.0}

    @editable:
        Categories:=array{sbi_environment_generation_categories.ChunkAndGridParameters}
    ChunkDivisionSize<public> : vector2 = vector2{X := 1024.0, Y := 1024.0}

    @editable:
        Categories:=array{sbi_environment_generation_categories.ChunkAndGridParameters}
    GridPointSize<public> : vector3 = vector3{X := 1024.0, Y := 1024.0, Z := 384.0}

    # Layer Parameters
    @editable:
        Categories:=array{sbi_environment_generation_categories.LayerParameters}
    LayerCount<public> : int = 4

    @editable:
        Categories:=array{sbi_environment_generation_categories.LayerParameters}       
    LayerDepth<public> : float = 1152.0

    @editable:
        Categories:=array{sbi_environment_generation_categories.LayerParameters}
    LayerInitialZ<public> : float = 384.0

    @editable:
        Categories:=array{sbi_environment_generation_categories.LayerParameters}
    LayerTerrainNoiseThresholdDecayMultiplier<public> : float = 0.9

    # Runtime Compiled Parameters
    var <private>BiomePerlinNoise<public> : perlin_noise =              perlin_noise{}

    var <private>TerrainPerlinNoise<public> : perlin_noise =            perlin_noise{}

    var <private>Layers<public> : []sbi_environment_layer =             array{}

    var <private>HumidityPoints<public> : []sbi_humidity_point =        array{}

    var <private>ChunkSizeWorldUnits<public> : vector2 =                vector2{}

    var <private>NumChunkNeg<public> : vector2i =                       vector2i{}

    var <private>NumChunkPos<public> : vector2i =                       vector2i{}

    var <private>TerrainPieceWeightSum<public> : float =                0.0

    # ! THIS IS NEW (TEMP?)
    var <private>HillSlopeTerrainPieceWeightSum<public> : float =       0.0
    # ! THIS IS NEW (TEMP?)

    var <private>TemperateBiomeWeightSum<public> : float =              0.0

    var <private>ChunkMap<public> : [int][int]sbi_environment_chunk =   map{}

    var <private>Compiled<public> : logic =                             false

    var <private>ChunkTotal<public> : int =                             0

    var <private>ChunksGenerated<public> : int =                        0

    GlobalChunkGeneratedEvent : event(sbi_environment_chunk) =          event(sbi_environment_chunk){}

    AllChunksGeneratedEvent : event() =                                 event(){}

    AllChunksFloorGeneratedEvent<public> : event() =                    event(){}

    var ChunksToRegenerate<public> : []sbi_environment_chunk =          array{}

    # DEBUG
    @editable:
        Categories:=array{sbi_environment_generation_categories.DebugParameters}
    ShowGroundSafeGridPoints : logic = false

    @editable:
        Categories:=array{sbi_environment_generation_categories.DebugParameters}
    ShowIslandBoundingBox : logic = false

    @editable:
        Categories:=array{sbi_environment_generation_categories.DebugParameters}
    ShowChunkVisual : logic = false

    @editable:
        Categories:=array{sbi_environment_generation_categories.DebugParameters}
    ShowHumidityPoints : logic = false

    DebugDrawer : debug_draw = debug_draw{}

    # Initialize
    Compile<public>()<suspends>:void =
        Print("Compiling Environment Parameters")
        BuildNoiseGenerators()
        Sleep(0.0)
        CalculateChunkCountSize()
        Sleep(0.0)
        InitializeChunkMap()
        Sleep(0.0)
        PrepTerrainLayers()
        Sleep(0.0)
        CalculateTerrainPieceWeights()
        Sleep(0.0)
        CalculateTemperateWeights()
        Sleep(0.0)
        HumidityVoroniDiagram()
        Sleep(0.0)
        SetGlobalDataReference()
        Sleep(0.0)
        spawn { AwaitChunksGenerated() }
        set Compiled = true

    # Build the Gradient Noise Objects
    BuildNoiseGenerators<private>()<suspends>:void =
        set BiomePerlinNoise = NewPerlinNoise(?Scale := BiomePerlinNoiseScale)
        Sleep(0.0)
        set TerrainPerlinNoise = NewPerlinNoise(?Octaves := 4, ?Scale := TerrainPerlinNoiseScale)

    # Calculate the Chunk Size and then retrieve the Chunk Count
    CalculateChunkCountSize<private>():void =
        set ChunkSizeWorldUnits = ChunkDivisionSize * ChunkDivisionCount
        if:
            CalculatedNumChunkNeg := ConvertV2i[vector2{X := EnvironmentBoundaries.Minimum.X, Y := EnvironmentBoundaries.Minimum.Y} / ChunkSizeWorldUnits]
            CalculatedNumChunkPos := ConvertV2i[vector2{X := EnvironmentBoundaries.Maximum.X, Y := EnvironmentBoundaries.Maximum.Y} / ChunkSizeWorldUnits]
        then:
            set NumChunkNeg = CalculatedNumChunkNeg
            set NumChunkPos = CalculatedNumChunkPos
        else:
            Print("ERROR: Could not convert Chunk Count XY to vector2i SBI")
            Err("Could not convert Chunk Count XY to vector2i SBI")

    # Using the Chunk Count we Initialize the Chunk Map
    InitializeChunkMap<private>()<suspends>:void =
        for(X := NumChunkNeg.X..NumChunkPos.X, Y := NumChunkNeg.Y..NumChunkPos.Y):
            set ChunkTotal += 1
            Sleep(0.0)
            Print("Initializing Chunk[{X},{Y}]")
            HalfChunkSize := (ChunkSizeWorldUnits / 2.0).ToV3(?Z := 0.0)
            StartingChunkPoint := vector3:
                X := (X * ChunkSizeWorldUnits.X) - HalfChunkSize.X
                Y := (Y * ChunkSizeWorldUnits.Y) - HalfChunkSize.Y
            # EndingChunkPoint := vector3:
            #     X := ((X + 1) * ChunkSizeWorldUnits.X) - HalfChunkSize.X
            #     Y := ((Y + 1) * ChunkSizeWorldUnits.Y) - HalfChunkSize.Y
            # CenterLocation := (StartingChunkPoint + EndingChunkPoint) / 2.0
            CenterLocation := StartingChunkPoint + HalfChunkSize
            NewChunk := sbi_environment_chunk:
                GridCoordinates := vector2i{X := X, Y := Y}
                StartLocation := StartingChunkPoint
                CenterLocation := CenterLocation
            if {set ChunkMap[X][Y] = NewChunk}
            else if {set ChunkMap[X] = map{Y => NewChunk}}
            else { Print("ERROR: Could not set Chunk at {X},{Y} Coordinates, this should be unreachable."), Err("Could not set Chunk at {X},{Y} Coordinates, this should be unreachable.") }

            if(ShowChunkVisual?):
                DebugDrawer.DrawBox(vector3{X := CenterLocation.X, Y := CenterLocation.Y, Z := 7680.0}, IdentityRotation(), ?Extent := vector3{X := ChunkSizeWorldUnits.X/2.0, Y := ChunkSizeWorldUnits.Y/2.0}, ?Color := NamedColors.White, ?Thickness := 10.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)

    # Prep the Terrain Layers by Precalculating Tolerances and Generating a Coordinate Offset for Noise Value Retrieval
    PrepTerrainLayers<private>():void =
        for(Layer := 0..LayerCount - 1):
            LayerTerrainNoiseThreshold := Pow(LayerTerrainNoiseThresholdDecayMultiplier, Layer * 1.0) * TerrainNoiseThreshold
            Print("Layer{Layer} Terrain Tolerance:{LayerTerrainNoiseThreshold}")
            set Layers += array:
                sbi_environment_layer:
                    TerrainNoiseThreshold := LayerTerrainNoiseThreshold
                    XYZCoordinateOffset := vector3:
                        X := GetRandomFloat(EnvironmentBoundaries.Minimum.X, EnvironmentBoundaries.Maximum.X)
                        Y := GetRandomFloat(EnvironmentBoundaries.Minimum.Y, EnvironmentBoundaries.Maximum.Y)
                        Z := Layer * LayerDepth + LayerInitialZ

    # Calculate Terrain Piece Weights to have Biases Towards Heavier Terrain Objects with Random Selection
    CalculateTerrainPieceWeights<private>():void =
        for(TerrainPiecePrototype : TerrainPiecePrototypes, TerrainPiecePrototype.Use?):
            set TerrainPieceWeightSum += TerrainPiecePrototype.Weighting
        # ! THIS IS NEW
        # for(HillSlopeTerrainPiece : HillSlopeTerrainPieces, HillSlopeTerrainPiece.Use?):
        #     set HillSlopeTerrainPieceWeightSum += HillSlopeTerrainPiece.Weighting
        # ! THIS IS NEW (TEMP)

    # Calculate Biome Weights to have Biases Towards Heavier Biomes for Noise Selection
    CalculateTemperateWeights<private>():void =
        for(TemperateBiome : TemperateBiomes):
            TemperateBiome.CalculateBiomeWeights()
            set TemperateBiomeWeightSum += TemperateBiome.Weighting

        for(TemperateBiome : TemperateBiomes):
            if(TemperateBiomeWeightSum = TemperateBiome.Weighting):
                set TemperateBiome.NormedWeighting = 1.0
            else:
                set TemperateBiome.NormedWeighting = TemperateBiome.Weighting / TemperateBiomeWeightSum

    # Randomly Plot Points around the Boundaries and Assign a Random Humidity Value for Biome Selection
    HumidityVoroniDiagram<private>():void =
        for(I := 1..HumidityPointCount):
            XCoordinate := GetRandomFloat(EnvironmentBoundaries.Minimum.X, EnvironmentBoundaries.Maximum.X)
            YCoordinate := GetRandomFloat(EnvironmentBoundaries.Minimum.Y, EnvironmentBoundaries.Maximum.Y)
            Location := vector3{X := XCoordinate, Y := YCoordinate, Z := 2560.0}
            if(ShowHumidityPoints?):
                DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Red, ?Thickness := 20.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
            set HumidityPoints += array:
                sbi_humidity_point:
                    Location := vector3{X := XCoordinate, Y := YCoordinate}
                    HumidityLevel := GetRandomFloat(0.0, 1.0)

    # Set Global Parameter Reference
    SetGlobalDataReference<private>():void =
        if(set GlobalEnvironmentGenerationData[GetSession()] = Self):
            Print("Successfuly set Global Environment Parameter Reference")
        else:
            Print("ERROR: Failed to set Global Environment Parameter Reference")
            Err("Failed to set Global Environment Parameter Reference")

    # Await Chunks Generated
    AwaitChunksGenerated()<suspends>:void =
        loop:
            GlobalChunkGeneratedEvent.Await()
            set ChunksGenerated += 1
            if(ChunksGenerated >= ChunkTotal):
                AllChunksGeneratedEvent.Signal()
                break
