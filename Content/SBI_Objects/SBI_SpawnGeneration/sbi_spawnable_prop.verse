
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /UnrealEngine.com/Temporary/SpatialMath }

using { SBI_VerseUtility }

# Get the cubic bezier parameter
GetCubicBezierParam(InterpolationType : interpolation_types):cubic_bezier_parameters =
    case(InterpolationType):
        interpolation_types.Linear =>
            return InterpolationTypes.Linear
        interpolation_types.Ease =>
            return InterpolationTypes.Ease
        interpolation_types.EaseIn =>
            return InterpolationTypes.EaseIn
        interpolation_types.EaseOut =>
            return InterpolationTypes.EaseOut  
        interpolation_types.EaseInOut =>
            return InterpolationTypes.EaseInOut

# Interpolation types
interpolation_types := enum:
    Linear
    Ease
    EaseIn
    EaseOut
    EaseInOut

# Some Offsets for shrink and grow
shrink_grow_keyframe_offset := class<concrete>():

    # Time it takes
    @editable       AnimationTime : float = 0.0
    # Rotations to apply
    @editable       DeltaRotationDegrees : vector3 = vector3{}
    # Translation
    @editable       DeltaLocation : vector3 = vector3{}
    # Interpolation Type
    @editable       InterpolationType : interpolation_types = interpolation_types.Ease

# Prop Wrappers that offers some extra parameters and functions
spawnable_prop<public> := class<concrete>(invalidatable):

    # Spawned Prop
    var MaybeSpawnedProp : ?creative_prop = false
    # Wait Finished
    WaitFinishedEvent<public> : event() = event(){}
    # When spawned
    SpawnedEvent<public> : event(creative_prop) = event(creative_prop){}
    # Finished Growing
    FinishedGrowEvent<public> : event(creative_prop) = event(creative_prop){}
    # Trigger Lifetime Start Event
    TriggerLifetimeStartEvent<public> : event() = event(){}
    # Started Shrink Event
    LifetimeFufilledEvent<public> : event(creative_prop) = event(creative_prop){}
    # Event when the spawned prop is disposed.
    DisposedEvent<public> : event() = event(){}
    # Asset to use to spawn.
    @editable       BPAsset : creative_prop_asset = DefaultCreativePropAsset
    # Location Offset.
    @editable       LocationOffset : vector3 = vector3{}
    # Wait time before spawning
    @editable       WaitTime : float = 0.0
    # Optional Grow Time, if there is none, the prop does not grow and immediately 
    @editable       OptionalGrow : ?shrink_grow_keyframe_offset = false
    # Optional Life Time, if there is none, the prop exists forever.
    @editable       OptionalLifetime<public> : ?float = false
    # Does lifetime auto start?
    @editable       LifetimeAutoStart : logic = true
    #  Optional Shrink Time, if there is none, after the lifetime the prop immediately is disposed.
    @editable       OptionalShrink : ?shrink_grow_keyframe_offset = false

    # Get current spawned prop
    GetCurrentSpawnedProp<public>()<transacts><decides>:creative_prop =
        MaybeSpawnedProp?

    # Spawns the Spawn Prop at function to clean up readibility elsewhere.
    SpawnPropAt<public>(Transform : transform, ?Test : logic = false):void = 
        spawn { SpawnToLifetime(Transform, ?Test := Test) }

    # Spawn Prop At Transform, this function can be used to Await Disposal
    SpawnToLifetime(Transform : transform, ?Test : logic = false)<suspends>:void =
        race:
            DisposedEvent.Await()
            block:
                var SpawnTransform : transform = Transform

                Sleep(WaitTime)
                WaitFinishedEvent.Signal()

                set SpawnTransform.Translation = SpawnTransform.Translation + LocationOffset

                if(Grow := OptionalGrow?):
                    set SpawnTransform.Scale = vector3{X := 0.01, Y := 0.01, Z := 0.01}
                    SpawnResult := SpawnProp(BPAsset, SpawnTransform)
                    if(Test?):
                        Print("SpawnResult: {SpawnResult(1)}")
                    MaybeSpawnedResult := SpawnResult(0)
                    if(NewSpawnedProp := MaybeSpawnedResult?):
                        set MaybeSpawnedProp = option{NewSpawnedProp}
                        SpawnedEvent.Signal(NewSpawnedProp)
                        GrowProp(NewSpawnedProp, Grow)
                    else if(Test?):
                        Print("Spawn Prop Fail, No Prop to Grow")

                else:
                    set SpawnTransform.Scale = vector3{X := 1.0, Y := 1.0, Z := 1.0}
                    SpawnResult := SpawnProp(BPAsset, SpawnTransform)
                    MaybeSpawnedResult := SpawnResult(0)
                    if(Test?):
                        Print("SpawnResult: {SpawnResult(1)}")
                    if(NewSpawnedProp := MaybeSpawnedResult?):
                        set MaybeSpawnedProp = option{NewSpawnedProp}
                        SpawnedEvent.Signal(NewSpawnedProp)
                    else if(Test?):
                        Print("Spawn Prop Fail, Can't Signal")


                if(Lifetime := OptionalLifetime?, SpawnedProp := MaybeSpawnedProp?):
                    if(not LifetimeAutoStart?):
                        TriggerLifetimeStartEvent.Await()
                    FufillLifetime(SpawnedProp, Lifetime)
                    if(Shrink := OptionalShrink?):
                        ShrinkProp(SpawnedProp, Shrink)
                    Dispose()

                else:
                    return

    # Grow Prop
    GrowProp(Prop : creative_prop, GrowOffset : shrink_grow_keyframe_offset)<suspends>:void =
        if(Prop.IsValid[], AnimController := Prop.GetAnimationController[]):

            Keyframes := array:
                keyframe_delta:
                    DeltaLocation := GrowOffset.DeltaLocation
                    DeltaRotation := MakeRotationFromYawPitchRollDegrees(GrowOffset.DeltaRotationDegrees.Z, GrowOffset.DeltaRotationDegrees.Y, GrowOffset.DeltaRotationDegrees.X)
                    DeltaScale := vector3{X := 100.0, Y := 100.0, Z := 100.0}
                    Time := GrowOffset.AnimationTime
                    Interpolation := GetCubicBezierParam(GrowOffset.InterpolationType)

            AnimController.SetAnimation(Keyframes, ?Mode := animation_mode.OneShot)
            AnimController.Play()

        Sleep(GrowOffset.AnimationTime)
        FinishedGrowEvent.Signal(Prop)

    # Fufill the Props Lifetime
    FufillLifetime(Prop : creative_prop, Time : float)<suspends>:void =
        if(Lifetime := OptionalLifetime?):
            Sleep(Lifetime)
            LifetimeFufilledEvent.Signal(Prop)

    # Shrink Prop
    ShrinkProp(Prop : creative_prop, ShrinkOffset : shrink_grow_keyframe_offset)<suspends>:void =
        if(Prop.IsValid[], AnimController := Prop.GetAnimationController[]):

            Keyframes := array:
                keyframe_delta:
                    DeltaLocation := ShrinkOffset.DeltaLocation
                    DeltaRotation := MakeRotationFromYawPitchRollDegrees(ShrinkOffset.DeltaRotationDegrees.Z, ShrinkOffset.DeltaRotationDegrees.Y, ShrinkOffset.DeltaRotationDegrees.X)
                    DeltaScale := vector3{X := 0.01, Y := 0.01, Z := 0.01}
                    Time := ShrinkOffset.AnimationTime
                    Interpolation := GetCubicBezierParam(ShrinkOffset.InterpolationType)

            AnimController.SetAnimation(Keyframes, ?Mode := animation_mode.OneShot)
            AnimController.Play()

        Sleep(ShrinkOffset.AnimationTime)

    # Is Valid
    IsValid<override>()<transacts><decides>:void =
        SpawnedProp := MaybeSpawnedProp?
        SpawnedProp.IsValid[]

    # Dispose
    Dispose<override>():void =
        if(SpawnedProp := MaybeSpawnedProp?, SpawnedProp.IsValid[]):
            set MaybeSpawnedProp = false
            SpawnedProp.Dispose()
            DisposedEvent.Signal()

    # Clone the Configurations for this Spawnable Prop
    Clone<public>()<transacts>:spawnable_prop =
        spawnable_prop:
            BPAsset := BPAsset
            LocationOffset := LocationOffset
            WaitTime := WaitTime
            OptionalGrow := OptionalGrow
            OptionalLifetime := OptionalLifetime
            OptionalShrink := OptionalShrink

    # Start Lifetime
    StartLifetime<public>():void =
        TriggerLifetimeStartEvent.Signal()