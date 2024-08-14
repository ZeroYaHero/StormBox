using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }

# perlin_device := class(creative_device):

#     StartingCoordinate`1 : vector3 = vector3{X := 25000.0, Y := 5000.0, Z := 75.0}
#     GridSize : vector2i = vector2i{X := 70, Y := 70}
#     IncrementSize : float = 10.0
#     var Octaves : int = 3
#     Frequency : float = 0.005
#     Wrap : int = 256


#     @editable       TerrainCube : creative_prop_asset = DefaultCreativePropAsset

#     @editable       AssetToSpawn : creative_prop_asset = DefaultCreativePropAsset
#     @editable       Octave2Button : button_device = button_device{}
#     @editable       Octave4Button : button_device = button_device{}
#     @editable       Octave8Button : button_device = button_device{}
#     @editable       Octave16Button : button_device = button_device{}

#     OnBegin<override>()<suspends>:void =
#         PerlinNoise := NewPerlinNoise(?Octaves := Octaves, ?Frequency := Frequency)

#         # SpawnedResultsArrays := for(X := 0..GridSize.X - 1):
#         #     Sleep(0.0)
#         #     for(Y := 0..GridSize.Y - 1):
#         #         Location := StartingCoordinate + vector3{X := X * IncrementSize, Y := Y * IncrementSize}
#         #         ZScale := ((PerlinNoise.FractalBrownianMotion2D(Location.X, Location.Y) + 1.0) / 2.0) + 0.1
#         #         Transform := transform{Translation := Location, Scale := vector3{X := 1.0, Y := 1.0, Z := ZScale}, Rotation := IdentityRotation()}
#         #         SpawnProp(AssetToSpawn, Transform)

#         # var MaybeFirstSpawned : ?creative_prop = false
#         # var LastSpawned : creative_prop = creative_prop{}
#         # var SpawnedCount : int = 0



#         # for(X := 0..48 - 1):
#         #     Sleep(0.0)
#         #     for(Y := 0..48 - 1):
#         #         Sleep(0.0)
#         #         for(Z := 0..16 - 1):
#         #             Location := vector3{X := -25000.0, Y := -25000.0, Z := 0.0} + vector3{X := X * 512.0, Y := Y * 512.0, Z := Z * 384.0}
#         #             if:
#         #                 NoiseValue := (PerlinNoise.FractalBrownianMotion3D(Location.X / 50.0, Location.Y / 50.0, (Location.Z * 1.3333) / 50.0) + 1.0) / 2.0
#         #                 NoiseValue > 0.8
#         #             then:
#         #                 Result := SpawnProp(TerrainCube, transform{Translation := Location, Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0}, Rotation := IdentityRotation()})
#         #                 if(SpawnedProp := Result(0)?):
#         #                     set SpawnedCount += 1
#         #                     if(not MaybeFirstSpawned?):
#         #                         set MaybeFirstSpawned = option{SpawnedProp}
#         #                     set LastSpawned = SpawnedProp

#         # Print("3D Noise Terrain Generation finished, {SpawnedCount} spawned")
#         # # Print("Distance between first spawn and last spawn: )
#         # if:
#         #     FirstSpawned := MaybeFirstSpawned?
#         #     FirstSpawned.IsValid[]
#         #     LastSpawned.IsValid[]
#         # then:
#         #     Print("Distance between first spawn and last spawn: {Distance(FirstSpawned.GetTransform().Translation, LastSpawned.GetTransform().Translation)}")

#         # race:
#         #     block:
#         #         Octave2Button.InteractedWithEvent.Await()
#         #         set Octaves = 2
#         #     block:
#         #         Octave4Button.InteractedWithEvent.Await()
#         #         set Octaves = 4
#         #     block:
#         #         Octave8Button.InteractedWithEvent.Await()
#         #         set Octaves = 8
#         #     block:
#         #         Octave16Button.InteractedWithEvent.Await()
#         #         set Octaves = 16

#         # for(SpawnedPropResults : SpawnedResultsArrays):
#         #     Sleep(0.0)
#         #     for(SpawnedPropResult : SpawnedPropResults, CreativeProp := SpawnedPropResult(0)?, CreativeProp.IsValid[]):
#         #         CreativeProp.Dispose()

#         # spawn { OnBegin() }


perlin_noise<public> := class:
    Octaves : int = 4
    Frequency : float = 0.005
    Scale : float = 1.0
    Wrap : int = 256
    Permutations : []int = array{}

    FractalBrownianMotion2D<public>(X : float, Y : float)<transacts>:float =
        NewX := X * Scale
        NewY := Y * Scale
        var Result : float = 0.0
        var Amplitude : float = 1.0
        var Freq : float = Frequency

        for(Octave := 0..Octaves - 1, N := Amplitude * Noise2D[NewX * Freq, NewY * Freq]):
            set Result += N

            set Amplitude *= 0.5
            set Freq *= 2.0

        return Result

    Noise2D<public>(XLoc : float, YLoc : float)<transacts><decides>:float =
        X := Mod[Floor[XLoc], Wrap]
        Y := Mod[Floor[YLoc], Wrap]
        XF := XLoc - Floor[XLoc] * 1.0
        YF := YLoc - Floor[YLoc] * 1.0

        VectorTopRight := vector2{X := XF - 1.0, Y := YF - 1.0}
        VectorTopLeft := vector2{X := XF, Y := YF - 1.0}
        VectorBottomRight := vector2{X := XF - 1.0, Y := YF}
        VectorBottomLeft := vector2{X := XF, Y := YF}

        ValueTopRight := Permutations[Permutations[X + 1] + Y + 1]
        ValueTopLeft := Permutations[Permutations[X] + Y + 1]
        ValueBottomRight := Permutations[Permutations[X + 1] + Y]
        ValueBottomLeft := Permutations[Permutations[X] + Y]

        DotTopRight := DotProduct(VectorTopRight, GetConstantVector2[ValueTopRight])
        DotTopLeft := DotProduct(VectorTopLeft, GetConstantVector2[ValueTopLeft])
        DotBottomRight := DotProduct(VectorBottomRight, GetConstantVector2[ValueBottomRight])
        DotBottomLeft := DotProduct(VectorBottomLeft, GetConstantVector2[ValueBottomLeft])

        U := Fade(XF)
        V := Fade(YF)

        return Lerp(Lerp(DotBottomLeft, DotTopLeft, V), Lerp(DotBottomRight, DotTopRight, V), U)

    GetConstantVector2(PValue : int)<transacts><decides>:vector2 =
        H : int = Mod[PValue, 4]
        if(H = 0):
            return vector2{X := 1.0, Y := 1.0}
        else if(H = 1):
            return vector2{X := -1.0, Y := 1.0}
        else if(H = 2):
            return vector2{X := -1.0, Y := -1.0}
        else:
            return vector2{X := 1.0, Y := -1.0}

    FractalBrownianMotion3D<public>(X : float, Y : float, Z : float)<transacts>:float =
        NewX := X * Scale
        NewY := Y * Scale
        NewZ := Z * Scale
        var Result : float = 0.0
        var Amplitude : float = 1.0
        var Freq : float = Frequency

        for(Octave := 0..Octaves - 1, N := Amplitude * Noise3D[NewX * Freq, NewY * Freq, NewZ * Freq]):
            set Result += N

            set Amplitude *= 0.5
            set Freq *= 2.0

        return Result

    Noise3D<public>(XLoc : float, YLoc : float, ZLoc : float)<transacts><decides>:float =
        X := Mod[Floor[XLoc], Wrap]
        Y := Mod[Floor[YLoc], Wrap]
        Z := Mod[Floor[ZLoc], Wrap]

        XF := XLoc - Floor[XLoc] * 1.0
        YF := YLoc - Floor[YLoc] * 1.0
        ZF := ZLoc - Floor[ZLoc] * 1.0

        VectorTopRightFront := vector3{X := XF - 1.0, Y := YF - 1.0, Z := ZF - 1.0}
        VectorTopLeftFront := vector3{X := XF, Y := YF - 1.0, Z := ZF - 1.0}
        VectorBottomRightFront := vector3{X := XF - 1.0, Y := YF, Z := ZF - 1.0}
        VectorBottomLeftFront := vector3{X := XF, Y := YF, Z := ZF - 1.0}
        VectorTopRightBack := vector3{X := XF - 1.0, Y := YF - 1.0, Z := ZF}
        VectorTopLeftBack := vector3{X := XF, Y := YF - 1.0, Z := ZF}
        VectorBottomRightBack := vector3{X := XF - 1.0, Y := YF, Z := ZF}
        VectorBottomLeftBack := vector3{X := XF, Y := YF, Z := ZF}

        ValueTopRightFront := Permutations[Permutations[Permutations[X + 1] + Y + 1] + Z + 1]
        ValueTopLeftFront := Permutations[Permutations[Permutations[X] + Y + 1] + Z + 1]
        ValueBottomRightFront := Permutations[Permutations[Permutations[X + 1] + Y] + Z + 1]
        ValueBottomLeftFront := Permutations[Permutations[Permutations[X] + Y] + Z + 1]
        ValueTopRightBack := Permutations[Permutations[Permutations[X + 1] + Y + 1] + Z]
        ValueTopLeftBack := Permutations[Permutations[Permutations[X] + Y + 1] + Z]
        ValueBottomRightBack := Permutations[Permutations[Permutations[X + 1] + Y] + Z]
        ValueBottomLeftBack := Permutations[Permutations[Permutations[X] + Y] + Z]
    
        DotTopRightFront := DotProduct(VectorTopRightFront, GetConstantVector3[ValueTopRightFront])
        DotTopLeftFront := DotProduct(VectorTopLeftFront, GetConstantVector3[ValueTopLeftFront])
        DotBottomRightFront := DotProduct(VectorBottomRightFront, GetConstantVector3[ValueBottomRightFront])
        DotBottomLeftFront := DotProduct(VectorBottomLeftFront, GetConstantVector3[ValueBottomLeftFront])
        DotTopRightBack := DotProduct(VectorTopRightBack, GetConstantVector3[ValueTopRightBack])
        DotTopLeftBack := DotProduct(VectorTopLeftBack, GetConstantVector3[ValueTopLeftBack])
        DotBottomRightBack := DotProduct(VectorBottomRightBack, GetConstantVector3[ValueBottomRightBack])
        DotBottomLeftBack := DotProduct(VectorBottomLeftBack, GetConstantVector3[ValueBottomLeftBack])
    
        U := Fade(XF)
        V := Fade(YF)
        W := Fade(ZF)
    
        LerpFront := Lerp(
            Lerp(Lerp(DotBottomLeftFront, DotTopLeftFront, V), Lerp(DotBottomRightFront, DotTopRightFront, V), U),
            Lerp(Lerp(DotBottomLeftBack, DotTopLeftBack, V), Lerp(DotBottomRightBack, DotTopRightBack, V), U),
            W
        )
        LerpBack := Lerp(
            Lerp(Lerp(DotBottomLeftBack, DotTopLeftBack, V), Lerp(DotBottomRightBack, DotTopRightBack, V), U),
            Lerp(Lerp(DotBottomLeftFront, DotTopLeftFront, V), Lerp(DotBottomRightFront, DotTopRightFront, V), U),
            W
        )
    
        return Lerp(W, LerpFront, LerpBack)

    GetConstantVector3(PValue : int)<transacts><decides>:vector3 =
        H : int = Mod[PValue, 8]
        if (H = 0):
            return vector3{X := 1.0, Y := 1.0, Z := 1.0}
        else if (H = 1):
            return vector3{X := -1.0, Y := 1.0, Z := 1.0}
        else if (H = 2):
            return vector3{X := 1.0, Y := -1.0, Z := 1.0}
        else if (H = 3):
            return vector3{X := 1.0, Y := 1.0, Z := -1.0}
        else if (H = 4):
            return vector3{X := -1.0, Y := -1.0, Z := 1.0}
        else if (H = 5):
            return vector3{X := -1.0, Y := 1.0, Z := -1.0}
        else if (H = 6):
            return vector3{X := 1.0, Y := -1.0, Z := -1.0}
        else:
            return vector3{X := -1.0, Y := -1.0, Z := -1.0}
        # H : int = Mod[PValue, 12]
        # if (H = 0):
        #     return vector3{X := 1.0, Y := 1.0, Z := 0.0}
        # else if (H = 1):
        #     return vector3{X := -1.0, Y := 1.0, Z := 0.0}
        # else if (H = 2):
        #     return vector3{X := 1.0, Y := -1.0, Z := 0.0}
        # else if (H = 3):
        #     return vector3{X := -1.0, Y := -1.0, Z := 0.0}
        # else if (H = 4):
        #     return vector3{X := 1.0, Y := 0.0, Z := 1.0}
        # else if (H = 5):
        #     return vector3{X := -1.0, Y := 0.0, Z := 1.0}
        # else if (H = 6):
        #     return vector3{X := 1.0, Y := 0.0, Z := -1.0}
        # else if (H = 7):
        #     return vector3{X := -1.0, Y := 0.0, Z := -1.0}
        # else if (H = 8):
        #     return vector3{X := 0.0, Y := 1.0, Z := 1.0}
        # else if (H = 9):
        #     return vector3{X := 0.0, Y := -1.0, Z := 1.0}
        # else if (H = 10):
        #     return vector3{X := 0.0, Y := 1.0, Z := -1.0}
        # else:
        #     return vector3{X := 0.0, Y := -1.0, Z := -1.0}

    Fade(T : float)<transacts>:float =
        return ((6 * T - 15.0) * T + 10.0) * T * T * T

NewPerlinNoise<public>(?Octaves : int = 3, ?Frequency : float = 0.005, ?Scale : float = 1.0, ?Wrap : int = 256)<transacts> : perlin_noise =
    perlin_noise:
        Octaves := Octaves
        Frequency := Frequency
        Scale := Scale
        Permutations := PermutationTable(Wrap)
        Wrap := Wrap

PermutationTable<public>(Wrap : int)<transacts>:[]int =
    Shuffled := Shuffle(for(I := 0..Wrap - 1) { I })
    Shuffled + Shuffled