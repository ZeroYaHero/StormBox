using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }
using { /Verse.org/Simulation/Tags }

using { SBI_EnvironmentGeneration }
using { SBI_VerseUtility }
using { SBI_Rewards }
using { SBI_Gameplay }

build_clear_explosive_tag := class(tag){}

glide_zone_tag := class(tag){}

# Storm Box Controller. Speaks for itself.
storm_box_controller<public> := class:

    # Storm Box Data
    StormBoxData<public> : storm_box_data
    # Game Event Manager
    GameEventManager<public> : sbi_game_event_manager
    # Storm Box Phase Reward\
    StormBoxPhaseReward<public> : sbi_reward
    # Signalled whenever a storm phase finished
    StormPhaseFinishedEvent<public> : event(storm_box_phase) = event(storm_box_phase){}
    # Signalled when a new storm phase is selected
    StormPhaseSelectedEvent<public> : event(storm_box_phase) = event(storm_box_phase){}
    # The previous phase
    var PreviousPhase : storm_box_phase = storm_box_phase{}
    # The current phase
    var CurrentPhase : storm_box_phase = storm_box_phase{}
    # Phase Count
    var PhaseCount : int = 0
    # Current Storm SFX
    var CurrentStormEdgeSFX : creative_prop = creative_prop{}
    # Storm Explosive Queue
    BuildClearExplosiveQueue : device_queue = device_queue{}
    # Debug Drawer
    DebugDrawer : debug_draw = debug_draw{}

    # Generate Storm
    GenerateStorm<public>():void =
        StormBoxData.AntiHealthPowerup.SetMagnitude(StormBoxData.TickDamageAmount)
        AdjustBounds()
        StormBoxData.ClearCine.Play()
        BuildExplosiveQueue()
        SubscribeGlideZones()

    SubscribeGlideZones():void =
        for(Obj : GetCreativeObjectsWithTag(glide_zone_tag{}), MutatorZone := mutator_zone_device[Obj]):
            MutatorZone.AgentEntersEvent.Subscribe(SkyTeleport)
        
        StormBoxData.SkyTeleporter.TeleportedEvent.Subscribe(OnSkyTeleport)

    SkyTeleport(Agent : agent):void =
        if(GameEventManager.IsShipped[player[Agent]]):
            StormBoxData.SkyTeleporter.Teleport(Agent)

    OnSkyTeleport(Agent : agent):void =
        if(Player := player[Agent]):
            spawn{GlideInvulnerability(Player)}

    GlideInvulnerability(Player : player)<suspends>:void =
        DealtDamageEvent := GameEventManager.GetDealtDamageEvent(Player)
        if(FortCharacter := Player.GetFortCharacter[]):
            FortCharacter.SetVulnerability(false)
            StormBoxData.SkyTeleportTimer.SetMaxDuration(StormBoxData.SkyInvulnerabilityTime)
            StormBoxData.SkyTeleportTimer.Start(Player)
            race:
                Sleep(StormBoxData.SkyInvulnerabilityTime)
                DealtDamageEvent.Await()
            StormBoxData.SkyTeleportTimer.Complete(Player)
            FortCharacter.SetVulnerability(true)


    # Build Explosive Queue
    BuildExplosiveQueue():void =
        for:
            Obj : GetCreativeObjectsWithTag(build_clear_explosive_tag{})
            ExplosiveDevice := explosive_device[Obj]
        do:
            BuildClearExplosiveQueue.Offer(ExplosiveDevice)

    # Get Storm Location
    GetStormLocation<public>()<transacts>:vector3 =
        return StormBoxData.StormProp.GetTransform().Translation

    # Get Previous Phase
    GetPreviousPhase<public>():storm_box_phase =
        return PreviousPhase

    # Get Current Phase
    GetCurrentPhase<public>():storm_box_phase =
        return CurrentPhase

    # Adjust Bounds
    AdjustBounds():void =
        GlobalEnvGenData := GetGlobalEnvGenData()

        if(StormBoxData.UseDebug?):
            DebugDrawer.DrawBox(vector3{}, IdentityRotation(), ?Extent := vector3{X := GlobalEnvGenData.EnvironmentBoundaries.Maximum.X, Y := GlobalEnvGenData.EnvironmentBoundaries.Maximum.Y, Z := GlobalEnvGenData.LayerCount * GlobalEnvGenData.LayerDepth}, ?Color := NamedColors.Red, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)

        set StormBoxData.Boundaries.Maximum.Z = GlobalEnvGenData.LayerCount * GlobalEnvGenData.LayerDepth
        set StormBoxData.Boundaries.Maximum.X = GlobalEnvGenData.EnvironmentBoundaries.Maximum.X - StormBoxData.XYDistanceFromTerrainMaxMin
        set StormBoxData.Boundaries.Maximum.Y = GlobalEnvGenData.EnvironmentBoundaries.Maximum.Y - StormBoxData.XYDistanceFromTerrainMaxMin
        set StormBoxData.Boundaries.Minimum.X = GlobalEnvGenData.EnvironmentBoundaries.Minimum.X + StormBoxData.XYDistanceFromTerrainMaxMin
        set StormBoxData.Boundaries.Minimum.Y = GlobalEnvGenData.EnvironmentBoundaries.Minimum.Y + StormBoxData.XYDistanceFromTerrainMaxMin

        if(StormBoxData.UseDebug?):
            DebugDrawer.DrawBox(vector3{}, IdentityRotation(), ?Extent := StormBoxData.Boundaries.Maximum, ?Color := NamedColors.Green, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)

        Print("New Storm Box Boundaries:\n{StormBoxData.Boundaries}")

        InitialPhase := storm_box_phase:
            Prop := StormBoxData.StormProp
            Location := vector3{Z := StormBoxData.Boundaries.Minimum.Z + StormBoxData.Boundaries.Maximum.Z / 2.0}
            Extents := StormBoxData.Extents
        set PreviousPhase = InitialPhase
        set CurrentPhase = InitialPhase

        Print("StormSettings MaxCoordZ: {StormBoxData.Boundaries.Maximum.Z}")
        if(StormBoxData.UseDebug?):
            DebugDrawer.DrawPoint(vector3{Z := StormBoxData.Boundaries.Maximum.Z}, ?Color := NamedColors.Purple, ?Thickness := 30.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)

    # Teleport Storm to Center of World
    TeleportStormToCenter():void =
        CenterLocation := vector3:
            Z := StormBoxData.Boundaries.Minimum.Z + (StormBoxData.Boundaries.Maximum.Z / 2.0)
        if:
            StormBoxData.StormProp.IsValid[]
            StormBoxData.StormProp.TeleportTo[CenterLocation, IdentityRotation()]
        then:
            Print("Successfully teleported Storm Prop to {CenterLocation}")
        else:
            Print("ERROR: COULD NOT TELEPORT STORM PROP TO {CenterLocation}")

        SkyTeleportLocation := vector3:
            Z := StormBoxData.Boundaries.Maximum.Z + StormBoxData.SkyTeleporterDistanceFromMaxZ
        if:
            StormBoxData.SkyTeleporter.TeleportTo[SkyTeleportLocation, IdentityRotation()]
        then:
            Print("Successfully teleported SkyTeleporter")
        else:
            Print("ERROR: COULD NOT TELEPORT SKY TELEPORTER TO {SkyTeleportLocation}")
        
        PostProcessNewTransform := transform:
            Translation := StormBoxData.PostProcessProp.GetTransform().Translation
            Rotation := IdentityRotation()
            Scale := vector3{X := 500.0, Y := 500.0, Z := 500.0}
        if:
            StormBoxData.PostProcessProp.IsValid[]
            StormBoxData.PostProcessProp.TeleportTo[PostProcessNewTransform]
        then:
            Print("Successfully teleported Post Process with new scale")
        else:
            Print("ERROR: Could not teleport Post Process Prop")
            
        set PreviousPhase = storm_box_phase{Location := CenterLocation, Extents := StormBoxData.Extents}

    # Storm Loop
    StormLoop<public>()<suspends>:void =
        Print("Infinite Storm Loop Starting...")
        loop:
            StormPhaseSelection()
            Wait()
            MoveStorm()

    # Select Storm Phase.
    StormPhaseSelection():void =
        Print("Selecting Storm Phase...")
        PhasesPerAxis : []storm_box_phase = 
            for(Axis : StormBoxData.Axises, RandomAxisLoc := GenerateRandomLocationForAxis[PreviousPhase.Location, Axis.NormalDirection]):
                storm_box_phase:
                    Prop := StormBoxData.StormProp
                    Location := RandomAxisLoc
                    Axis := Axis
                    Extents := StormBoxData.Extents
        if:
            OptionOne := PhasesPerAxis[GetRandomInt(0, PhasesPerAxis.Length - 1)]
            OptionTwo := PhasesPerAxis[GetRandomInt(0, PhasesPerAxis.Length - 1)]
            OptionThree := PhasesPerAxis[GetRandomInt(0, PhasesPerAxis.Length - 1)]
        then:
            Print("Achieved 3 Optional Phases\nOptionOne:{OptionOne.Axis.NormalDirection}\nOptionTwo:{OptionTwo.Axis.NormalDirection}\nOptionThree:{OptionThree.Axis.NormalDirection}")
            set PreviousPhase = CurrentPhase
            set CurrentPhase = SelectBestPhase(OptionOne, OptionTwo, OptionThree)
            PlaceExplosives(PreviousPhase, CurrentPhase)
            spawn{RegenerateChunks(CurrentPhase)} # I would like this to use Previous Phase here too...
            StormPhaseSelectedEvent.Signal(CurrentPhase)
            Print("Signalled For PhaseSelectedEvent")
        else:
            Print("Failed to get phase for an axis")

    # Spawn Storm SFX
    SpawnStormSFX(SFXProp : creative_prop_asset)<transacts><decides>:creative_prop =
        MaybeStormSFXProp := SpawnProp(SFXProp, PreviousPhase.Location, IdentityRotation())
        MaybeStormSFXProp(0)?

    # Make the storm wait
    Wait()<suspends>:void =
        if(PhaseCount = 0):
            TeleportStormToCenter()
        StormBoxData.StormDeviceForSFX.DestroyStorm()
        StormBoxData.StormDeviceForSFX.GenerateStorm()
        Print("Storm Wait...")
        Sleep(StormBoxData.WaitTime)

    # Move Storm
    MoveStorm()<suspends>:void =
        Print("Moving Storm...")
        # Play the axis cine.
        CurrentPhase.Axis.Cine.Play()
        # Dispose Storm Edge SFX
        if(CurrentStormEdgeSFX.IsValid[]):
            CurrentStormEdgeSFX.Dispose()
        # Move SFX prop and
        sync:
            StormBoxData.SkyTeleporter.MoveTo(vector3{X := CurrentPhase.Location.X, Y := CurrentPhase.Location.Y, Z := StormBoxData.Boundaries.Maximum.Z + StormBoxData.SkyTeleporterDistanceFromMaxZ}, IdentityRotation(), StormBoxData.MoveTime)
            StormBoxData.StormProp.MoveTo(CurrentPhase.Location, IdentityRotation(), StormBoxData.MoveTime)
            if(SFXProp := SpawnStormSFX[StormBoxData.StormSFX.MovingEdge]):
                set CurrentStormEdgeSFX = SFXProp
                SFXProp.MoveTo(CurrentPhase.Location, IdentityRotation(), StormBoxData.MoveTime)
        # Dispose and spawn new 
        if:
            CurrentStormEdgeSFX.IsValid[]
            SFXProp := SpawnStormSFX[StormBoxData.StormSFX.StillEdge]
        then:
            CurrentStormEdgeSFX.Dispose()
            set CurrentStormEdgeSFX = SFXProp
            StormBoxData.ClearCine.Play()
    
        set PhaseCount += 1
        set PreviousPhase = CurrentPhase
        StormPhaseFinishedEvent.Signal(PreviousPhase)

    # Check an Agents Safety in relation to the Safe Zone.
    CheckAgentSafetyState<public>(Agent : agent)<suspends>:void =
        race:
            loop:
                StormPhaseFinishedEvent.Await()
                StormBoxPhaseReward.Reward(Agent)
            loop:
                Sleep(0.0)
                if(not StormBoxData.SafeZone.IsInVolume[Agent]):
                    Sleep(StormBoxData.TickTime)
                    loop:
                        if(not StormBoxData.SafeZone.IsInVolume[Agent]):
                            StormBoxData.StormSFX.Damage.Play(Agent)
                            StormBoxData.RainVFXAdd.Pickup(Agent)
                            StormBoxData.AntiHealthPowerup.Pickup(Agent)
                            # if(FortCharacter := Agent.GetFortCharacter[]):
                            #     FortCharacter.SetHealth(FortCharacter.GetHealth() - StormSettings.TickDamageAmount) # This is where we could check if close to death, get recent damager, kill with that.
                        else:
                            StormBoxData.RainVFXRemove.Pickup(Agent)
                            break
                        Sleep(StormBoxData.TickTime)
            if(FortChar := Agent.GetFortCharacter[]):
                FortChar.EliminatedEvent().Await()
            else:
                Sleep(Inf)

    # Generates a random location in the direction of axis starting at origin
    GenerateRandomLocationForAxis(Origin : vector3, Axis : vector3)<transacts><decides>:vector3 =
        var MinV3:vector3 = Origin + (Axis * StormBoxData.MinDistance)
        StormBoxData.Boundaries.WithinBounds[MinV3]
        var MaxV3:vector3 = Origin + (Axis * StormBoxData.MaxDistance)
        var MinDist:float = if(Axis.X <> 0.0) then StormBoxData.MinDistance.X else if(Axis.Y <> 0.0) then StormBoxData.MinDistance.Y else StormBoxData.MinDistance.Z
        var MaxDist:float = if(Axis.X <> 0.0) then StormBoxData.MaxDistance.X else if(Axis.Y <> 0.0) then StormBoxData.MaxDistance.Y else StormBoxData.MaxDistance.Z
        if(not StormBoxData.Boundaries.WithinBounds[MaxV3]):
            OriginBlankAxis := Origin.SetToZero(Axis)
            if(Axis.IsEqualTo[StormBoxData.XPos.NormalDirection] or Axis.IsEqualTo[StormBoxData.YPos.NormalDirection] or Axis.IsEqualTo[StormBoxData.ZPos.NormalDirection]):
                set MaxV3 = OriginBlankAxis + (Axis * StormBoxData.Boundaries.Maximum)
            else:
                set MaxV3 = OriginBlankAxis + (Axis * (Axis * StormBoxData.Boundaries.Minimum))
            set MaxDist = Distance(Origin, MaxV3)
        RandomizedDistanceFromOrigin := GetRandomFloat(MinDist, MaxDist)
        NewAxisAddition := Axis * RandomizedDistanceFromOrigin
        NewLocation := Origin + NewAxisAddition
        StormBoxData.Boundaries.WithinBounds[NewLocation]
        return NewLocation

    # Select the Best Phase out of three
    # Change the format to picking a random amount, and then 
    SelectBestPhase(One : storm_box_phase, Two : storm_box_phase, Three : storm_box_phase)<transacts>:storm_box_phase =
        PrevAxis := PreviousPhase.Axis.NormalDirection
        OneAxis := One.Axis.NormalDirection
        TwoAxis := Two.Axis.NormalDirection
        TriAxis := Three.Axis.NormalDirection

        if(OneAxis.IsEqualTo[TwoAxis].IsEqualTo[TriAxis]): # If they are all equal
            return One
        else if(not OneAxis.IsNegativeOf[PrevAxis] and not OneAxis.IsEqualTo[PrevAxis]): # If one is not the negative nor the same as previous.
            return One
        else if(not TwoAxis.IsNegativeOf[PrevAxis] and not TwoAxis.IsEqualTo[PrevAxis]): # If two is not the negative nor the same as previous.
            return Two
        else if(not TriAxis.IsNegativeOf[PrevAxis] and not TriAxis.IsEqualTo[PrevAxis]): # If three is not the negative nor the same as previous.
            return Three
        
        else if(not OneAxis.IsNegativeOf[PrevAxis]): # If one is at least not the negative of previous.
            return One
        else if(not TwoAxis.IsNegativeOf[PrevAxis]): # If two is at least not the negative of previous.
            return Two
        else if(not TriAxis.IsNegativeOf[PrevAxis]): # If one is at least not the negative of previous.
            return Three

        else if(not OneAxis.IsEqualTo[PrevAxis]): # If one is at least not equal to previous.
            return One
        else if(not TwoAxis.IsEqualTo[PrevAxis]): # If two is at least not equal to previous.
            return Two
        else if(not TriAxis.IsEqualTo[PrevAxis]): # If three is at least not equal to previous.
            return Three
        else:
            return One # This case does not occur.

    # Place Explosives
    PlaceExplosives(PrevPhase : storm_box_phase, NextPhase : storm_box_phase):void =
        if:
            PhaseUnitVector := (NextPhase.Location - PrevPhase.Location).MakeUnitVector[]
            ExplosivesToPlaceCount := Floor[Distance(PrevPhase.Location, NextPhase.Location) / StormBoxData.BuildClearExplosiveRadius]
        then:
            for:
                I := 0..ExplosivesToPlaceCount - 2
                ExplosiveDevice := explosive_device[BuildClearExplosiveQueue.Poll[]]
            do:
                ExplosiveLocation := PrevPhase.Location + ((PhaseUnitVector * StormBoxData.BuildClearExplosiveRadius) * (I * 1.0))
                if(ExplosiveDevice.TeleportTo[ExplosiveLocation, IdentityRotation()]):
                    spawn{ClearBuilds(ExplosiveDevice)}
                else:
                    Print("WARNING: Failed to teleport Explosive Device to {ExplosiveLocation}")
        else:
            Print("WARNING: Failed to make Unit Vector between {NextPhase.Location} and {PrevPhase.Location}")

    # Clear Builds
    ClearBuilds(ExplosiveDevice : explosive_device)<suspends>:void =
        ExplosiveDevice.Reset()
        StormPhaseFinishedEvent.Await()
        StormPhaseFinishedEvent.Await() # ! # TODO: This is new
        if(PlayerSignature := GameEventManager.GetPlayers()[0]):
            ExplosiveDevice.Explode(PlayerSignature)
        BuildClearExplosiveQueue.Offer(ExplosiveDevice)

    # Ugh I hate this
    RegenerateChunks(NextPhase : storm_box_phase)<suspends>:void =
        Sleep(0.3) # This sleep is here just to regenerate after explosions are set off
        GlobalEnvGenData := GetGlobalEnvGenData()
        CurrentLocation := GetStormLocation()
        var MinimumLocation : vector3 = vector3{}
        var MaximumLocation : vector3 = vector3{}
        var ChunkPath : []sbi_environment_chunk = array{}

        if(Abs(NextPhase.Axis.NormalDirection).IsEqualTo[vector3{X := 1.0}] or Abs(NextPhase.Axis.NormalDirection).IsEqualTo[vector3{Y := 1.0}]):
            if(NextPhase.Location.X > CurrentLocation.X or NextPhase.Location.Y >  CurrentLocation.Y):
                set MinimumLocation = BoxToWorld(CurrentLocation, StormBoxData.Extents)(0)
                set MaximumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(1)
            else:
                set MinimumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(0)
                set MaximumLocation = BoxToWorld(CurrentLocation, StormBoxData.Extents)(1)
        else:
            set MinimumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(0)
            set MaximumLocation = BoxToWorld(NextPhase.Location, NextPhase.Extents)(1)

        if(StormBoxData.UseDebug?):
            MinLocNoZ := vector3{X := MinimumLocation.X, Y := MinimumLocation.Y}
            MaxLocNoZ := vector3{X := MaximumLocation.X, Y := MaximumLocation.Y}
            DebugDrawer.DrawLine(MinLocNoZ, MinLocNoZ + vector3{Z := 7680.0}, ?Color := NamedColors.Yellow, ?Thickness := 10.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxData.WaitTime + StormBoxData.MoveTime)
            DebugDrawer.DrawLine(MaxLocNoZ, MaxLocNoZ + vector3{Z := 7680.0}, ?Color := NamedColors.Blue, ?Thickness := 10.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxData.WaitTime + StormBoxData.MoveTime)

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
        #         if(StormBoxData.UseDebug?):
        #             Location := vector3{X := CurrentChunk.CenterLocation.X, Y := CurrentChunk.CenterLocation.Y, Z := 7680.0}
        #             DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Grey, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxData.WaitTime + StormBoxData.MoveTime)
        #         CurrentChunk

        #     ChunksToRegenerate := Difference(GlobalEnvGenData.ChunksToRegenerate, ChunkPath)
        #     for(ChunkToRegenerate : ChunksToRegenerate):
        #         if(StormBoxData.UseDebug?):
        #             Location := vector3{X := ChunkToRegenerate.CenterLocation.X, Y := ChunkToRegenerate.CenterLocation.Y, Z := 7680.0}
        #             DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Green, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxData.WaitTime + StormBoxData.MoveTime)
        #         ChunkToRegenerate.RespawnMaterials()

        #     set GlobalEnvGenData.ChunksToRegenerate = ChunkPath

        if(MinimumChunkCoords := GetChunkCoordinates[MinimumLocation]):
            Print("MinChunkCoords:{MinimumChunkCoords}")
            if(MaximumChunkCoords := GetChunkCoordinates[MaximumLocation]):
                Print("MaxChunkCoords:{MaximumChunkCoords}")
                set ChunkPath = for:
                    X := MinimumChunkCoords.X..MaximumChunkCoords.X
                    Y := MinimumChunkCoords.Y..MaximumChunkCoords.Y
                    CurrentChunk := GetChunk[X, Y]
                do:
                    if(StormBoxData.UseDebug?):
                        Location := vector3{X := CurrentChunk.CenterLocation.X, Y := CurrentChunk.CenterLocation.Y, Z := 7680.0}
                        DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Grey, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxData.WaitTime + StormBoxData.MoveTime)
                    CurrentChunk

            else if(MinimumChunk := GetChunk[MinimumChunkCoords.X, MinimumChunkCoords.Y]):
                set ChunkPath = array{MinimumChunk}
        else if:
            MaximumChunkCoords := GetChunkCoordinates[MaximumLocation]
            MaximumChunk := GetChunk[MaximumChunkCoords.X, MaximumChunkCoords.Y]
        then:
            Print("MaxChunkCoords:{MaximumChunkCoords}")
            set ChunkPath = array{MaximumChunk}
            
        ChunksToRegenerate := Difference(GlobalEnvGenData.ChunksToRegenerate, ChunkPath)
        for(ChunkToRegenerate : ChunksToRegenerate):
            if(StormBoxData.UseDebug?):
                Location := vector3{X := ChunkToRegenerate.CenterLocation.X, Y := ChunkToRegenerate.CenterLocation.Y, Z := 7680.0}
                DebugDrawer.DrawPoint(Location, ?Color := NamedColors.Green, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.FiniteDuration, ?Duration := StormBoxData.WaitTime + StormBoxData.MoveTime)
            ChunkToRegenerate.RespawnMaterials()

        set GlobalEnvGenData.ChunksToRegenerate = ChunkPath
