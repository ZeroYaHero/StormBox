using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Random }

using { SBI_StormBoxStorm }
using { SBI_Lobby }
using { SBI_Rewards }
using { SBI_EnvironmentGeneration }
using { SBI_VerseUtility }
using { SBI_Gameplay }

sbi_spawn_generator<public> := class:

    # Spawn Generation Data
    SpawnGenerationData<public> : sbi_spawn_generation_data
    # Storm Box Controller
    StormBoxController<public> : storm_box_controller
    # Queue Box
    QueueBox<public> : sbi_queue_box
    # Package Reward
    PackageReward<public> : sbi_reward
    # Ship Reward
    ShipReward<public> : sbi_reward
    # Player Interaction Manager
    GameEventManager<public> : sbi_game_event_manager
    # Explosive Devices Queue
    ExplosiveQueue : device_queue = device_queue{}
    # Teleporter Devices Queue
    TeleporterQueue : device_queue = device_queue{}
    # Spawn Queue Offer Event
    SpawnQueueOfferEvent : event() = event(){}
    # Current Active Added Event
    SpawnerAddedEvent : event() = event(){}
    # AgentSpawnQueue
    var AgentSpawnQueue : agent_queue = agent_queue{}
    # Current Active Protected Spawners
    var CurrentActiveSpawners : []sbi_spawn = array{}
    # List of Queued
    var AgentsEnteredQueueMutator : []agent = array{}

    DebugDrawer : debug_draw = debug_draw{}

    # Initialize.
    Initialize<public>():void =
        QueueBox.Mutator.AgentEntersEvent.Subscribe(HandleSpawnQueueMutatorEnter)
        for(Obj : GetCreativeObjectsWithTag(spawn_explosive_queue{}), ExplosiveDevice := explosive_device[Obj]):
            ExplosiveQueue.Offer(ExplosiveDevice)
        for(Obj : GetCreativeObjectsWithTag(spawn_teleporter_queue{}), TeleporterDevice := teleporter_device[Obj]):
            TeleporterQueue.Offer(TeleporterDevice)
        spawn{ProcessCurrentActive()}
        spawn{ProcessAgentSpawnQueue()}
        AllowSpawnQueue()

    # Allow Spawn Queue
    AllowSpawnQueue():void =
        QueueBox.Mutator.Enable()
        QueueBox.OuterQueueBarrier.Disable()

    # Process Current Active
    ProcessCurrentActive()<suspends>:void =
        loop:
            SpawnerAddedEvent.Await()
            Print("Spawner Added")
            for:
                Index -> ActiveSpawner : CurrentActiveSpawners
                ActiveSpawner.Expired? or CurrentActiveSpawners.Length >= SpawnGenerationData.MaxSpawnersAtOnce
                ActiveSpawnerRemoved := CurrentActiveSpawners.RemoveElement[Index]
            do:
                Print("Found either an expired spawn or one that exceeds Spawn Limits\nDisposing Expired Spawn...")
                ActiveSpawnerGridPoint := ActiveSpawner.GridPoint
                ActiveSpawnerGridPoint.RemoveSpawn()
                ActiveSpawner.Dispose()
                set CurrentActiveSpawners = ActiveSpawnerRemoved
                if:
                    ChunkCoordinates := GetChunkCoordinates[ActiveSpawner.GridPoint.Location]
                    Chunk := GetChunk[ChunkCoordinates.X, ChunkCoordinates.Y]
                    ActiveSpawnerGridPoint.OccupiedCount <= 0
                    Chunk.NullifyGridPoint[ActiveSpawner.GridPoint]

    # Process Agent Spawn Queue
    ProcessAgentSpawnQueue()<suspends>:void =
        loop:
            Print("Awaiting Agent Entering Lobby Box")
            SpawnQueueOfferEvent.Await()
            Print("Agent wants to Enter the Storm Box")
            loop:
                if(AgentSpawnQueue.IsEmpty[]):
                    Print("AgentSpawnQueue IS Empty; Breaking Loop")
                    break
                else if(PolledAgent := AgentSpawnQueue.Poll[]):
                    Print("AgentSpawnQueue is NOT Empty")
                    Print("Polled Agent")
                    Print("AgentSpawnQueueSize: {AgentSpawnQueue.Size()}")
                    BuildSBISpawn(?MaybeAgentToSpawn := option{PolledAgent}, ?MaybeExplosive := PollExplosive(), ?MaybeTeleporter := PollTeleporter())

    # On Agent Spawn Queue Mutator
    HandleSpawnQueueMutatorEnter(Agent : agent):void =
        if(not AgentsEnteredQueueMutator.Find[Agent]):
            spawn{AwaitElimination(Agent)}
            set AgentsEnteredQueueMutator += array{Agent}
            if(Player := player[Agent]):
                GameEventManager.PlayerStormBoxPackagedEvent.Signal(Player)
                PackageReward.Reward(Player)
                SpawnGenerationData.PackageHUDMessage.Show(Agent)
            QueueBox.BoxBarrier.RemoveFromIgnoreList(Agent)
            spawn{OnSpawnQueueMutatorEnter(Agent)}

    AwaitElimination(Agent : agent)<suspends>:void =
        if(FortCharacter := Agent.GetFortCharacter[]):
            FortCharacter.EliminatedEvent().Await()
            set AgentsEnteredQueueMutator = AgentsEnteredQueueMutator.RemoveAllElements(Agent)

    # These are seperated so we can choose a delay that does not effect others queueing process.
    OnSpawnQueueMutatorEnter(Agent : agent)<suspends>:void =
        Sleep(0.3) # Changed from attempt delay
        if(not AgentSpawnQueue.Find[Agent]): # Check if they are already queued
            AgentSpawnQueue.Offer(Agent)
            SpawnQueueOfferEvent.Signal()

    # Poll the explosive used for clearing builds in the area
    PollExplosive():?explosive_device = 
        if(Explosive := explosive_device[ExplosiveQueue.Poll[]]):
            return option{Explosive}
        false

    # Poll the teleporter used for teleporting the player
    PollTeleporter():?teleporter_device = 
        if(Teleporter := teleporter_device[TeleporterQueue.Poll[]]):
            return option{Teleporter}
        false

    # Link all the assets, devices, and data needed for the Protected Spawn.
    BuildSBISpawn(?MaybeAgentToSpawn : ?agent = false, ?MaybeExplosive : ?explosive_device = false, ?MaybeTeleporter : ?teleporter_device = false)<suspends>:void =
        race:
            if(FortCharacter := MaybeAgentToSpawn?.GetFortCharacter[]):
                if(FortCharacter.IsActive[]):
                    FortCharacter.EliminatedEvent().Await()
                else:
                    return
            else:
                Sleep(Inf)
            block:
                if(Agent := MaybeAgentToSpawn?):
                    SpawnGenerationData.ShippingHUDMessage.Show(Agent)
                for:
                    I := 1..SpawnGenerationData.MaxAttemptCount
                do:
                    Print("Spawn Build Attempt: {I}")
                    if((I * 1.0) > ((SpawnGenerationData.MaxAttemptCount * 1.0) / 2.0), Agent := MaybeAgentToSpawn?):
                        SpawnGenerationData.QueueWaitHUDMessage.Show(Agent)
                    MaybeGeneratedSpawnLocation := GenerateSpawnLocation(AttemptNo := I)
                    if:
                        GeneratedSpawnLocation := MaybeGeneratedSpawnLocation?
                        ChunkCoordinates := GetChunkCoordinates[GeneratedSpawnLocation]
                        Chunk := GetChunk[ChunkCoordinates.X, ChunkCoordinates.Y]
                    then:
                        var SharedGridPoint : sbi_grid_point = sbi_grid_point{Location := GeneratedSpawnLocation}
                        if(CurrentGridPoint := Chunk.GetGridPointAt[GeneratedSpawnLocation]?): # ! # TODO: # FIXME: What happens if this is null?
                            set SharedGridPoint = CurrentGridPoint
                        else if:
                            Chunk.AddGridPoint[SharedGridPoint]
                        else:
                            Print("ERROR: Could not add Grid Point to Chunk, this should be unreachable.")
                            if(Agent := MaybeAgentToSpawn?):
                                EliminateAgent(Agent)
                            return

                        SharedGridPoint.AddSpawn()

                        SBISpawn := sbi_spawn:
                            MaybeAgentToSpawn := MaybeAgentToSpawn
                            ReferenceObject := QueueBox.QueueBoxProp
                            Assets := SpawnGenerationData.PlayerSpawnerAssets.Clone()
                            MaybeExplosive := MaybeExplosive
                            MaybeTeleporter := MaybeTeleporter
                            SpawnLoc := GeneratedSpawnLocation
                            GridPoint := SharedGridPoint

                        if(MaybeAgentToSpawn?):
                            spawn{AwaitAgentTeleport(SBISpawn.AgentTeleportedEvent)}
                        if(MaybeExplosive?):
                            spawn{AwaitExplosiveRetirement(SBISpawn.ExplosiveRetiredEvent)}

                        SBISpawn.Initialize()

                        set CurrentActiveSpawners += array{SBISpawn}
                        SpawnerAddedEvent.Signal()
                        return

                    else:
                        Sleep(SpawnGenerationData.AttemptDelay)

                if(Agent := MaybeAgentToSpawn?, Player := player[Agent]):
                    EliminateAgent(Agent)

    # Generate Spawn Location
    GenerateSpawnLocation(AttemptNo : int):?vector3 =
        if(SpawnGenerationData.UseDebug?):
            DebugDrawer.Clear()
        CurrentStorm := StormBoxController.GetCurrentPhase()
        CurrentStormLocation := CurrentStorm.Prop.GetTransform().Translation
        CurrentStormAxis := CurrentStorm.Axis.NormalDirection
        OtherAxises := vector3{X := 1.0, Y := 1.0, Z := 1.0} - Abs(CurrentStormAxis)
        AdjustedExtents := CurrentStorm.Extents - (SpawnGenerationData.ExtentTolerance * OtherAxises)
        AxisExtent := Abs(CurrentStormAxis) * AdjustedExtents
        AxisExtentDivided := AxisExtent / Remap(AttemptNo * 1.0, 1.0, SpawnGenerationData.MaxAttemptCount * 1.0, SpawnGenerationData.MaxSpawnerZoneDivisor, SpawnGenerationData.MinSpawnerZoneDivisor)
        AxisZeroedExtents := OtherAxises * AdjustedExtents
        NewExtents := AxisZeroedExtents + AxisExtentDivided
        NewLocation := (CurrentStormLocation + (CurrentStormAxis * AxisExtent)) - (AxisExtentDivided * CurrentStormAxis) - <# THIS IS NEW #> (CurrentStormAxis * SpawnGenerationData.ExtentTolerance) # ! # FIXME IF BROKEN
        if(SpawnGenerationData.UseDebug?):
            DebugDrawer.DrawBox(NewLocation, IdentityRotation(), ?Extent := NewExtents, ?Color := NamedColors.Blue, ?Thickness := 50.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
        MinMax := BoxToWorld(NewLocation, NewExtents)
        BoxSize := Abs(NewExtents * 2.0)
        EnvGenData := GetGlobalEnvGenData()
        Print("BoxMin: {MinMax(0)}, BoxMax: {MinMax(1)}")
        if:
            GridPointSizeMultiplied := EnvGenData.GridPointSize * SpawnGenerationData.GridPointSamplingMultiplier
            Minimum := vector3:
                X := Round[MinMax(0).X / GridPointSizeMultiplied.X] * GridPointSizeMultiplied.X
                Y := Round[MinMax(0).Y / GridPointSizeMultiplied.Y] * GridPointSizeMultiplied.Y
                Z := Round[MinMax(0).Z / GridPointSizeMultiplied.Z] * GridPointSizeMultiplied.Z

            GridCountX := Floor[BoxSize.X / GridPointSizeMultiplied.X]
            GridCountY := Floor[BoxSize.Y / GridPointSizeMultiplied.Y]
            GridCountZ := Floor[BoxSize.Z / GridPointSizeMultiplied.Z]
        then:
            RetVal := for:
                X := 0..GridCountX
                Y := 0..GridCountY
                Z := 0..GridCountZ
                NewPoint := Minimum + vector3:
                    X := GridPointSizeMultiplied.X * X
                    Y := GridPointSizeMultiplied.Y * Y
                    Z := GridPointSizeMultiplied.Z * Z
                NewPoint.X >= MinMax(0).X and NewPoint.X <= MinMax(1).X
                NewPoint.Y >= MinMax(0).Y and NewPoint.Y <= MinMax(1).Y
                NewPoint.Z >= MinMax(0).Z and NewPoint.Z <= MinMax(1).Z
                SpawnerSafe[NewPoint]
            do:
                if(SpawnGenerationData.UseDebug?):
                    DebugDrawer.DrawPoint(NewPoint, ?Color := NamedColors.Red, ?Thickness := 15.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                NewPoint
            if(RandomElement := RetVal[GetRandomInt(0, RetVal.Length - 1)]):
                Print("Successfully retrieved an SBI Spawn Location Element, returning as an option but it is not false!")
                return option{RandomElement}
            else:
                Print("WARNING: There are no SBI Spawn Locations generated.")
        else:
            Print("WARNING: Failed to Round/Floor points for the Spawn Generation within the Storm Box")
        return false

    
    # If a location is safe for a spawner
    SpawnerSafe(Location : vector3)<transacts><decides>:void =
        ChunkCoordinates := GetChunkCoordinates[Location]
        Chunk := GetChunk[ChunkCoordinates.X, ChunkCoordinates.Y]
        if(GridPoint := Chunk.GetGridPointAt[Location]?):
            not GridPoint.SpawnPresent?
            GridPoint.PointType = sbi_grid_point_type.Ground or
            GridPoint.PointType = sbi_grid_point_type.Surface or
            GridPoint.PointType = sbi_grid_point_type.Unoccupied

    # Await Agent Teleport
    AwaitAgentTeleport(TeleportEvent : event(tuple(agent, ?teleporter_device)))<suspends>:void =
        AgentMaybeTeleporter := TeleportEvent.Await()
        if(Player := player[AgentMaybeTeleporter(0)]):
            GameEventManager.PlayerStormBoxShippedEvent.Signal(Player)
            spawn{SpawnInvulnerability(Player)}
            # set AgentsEnteredQueueMutator = AgentsEnteredQueueMutator.RemoveAllElements(Player) # ? # TODO: If Elimination isn't always the standard for getting back to the lobby, this may need to return. 
        SpawnGenerationData.ShippedHUDMessage.Show(AgentMaybeTeleporter(0))
        ShipReward.Reward(AgentMaybeTeleporter(0))
        spawn{StormBoxController.CheckAgentSafetyState(AgentMaybeTeleporter(0))}
        if(Teleporter := AgentMaybeTeleporter(1)?):
            TeleporterQueue.Offer(Teleporter)

    # Await an Explosive Retired Event
    AwaitExplosiveRetirement(RetireEvent : event(explosive_device))<suspends>:void =
        Explosive := RetireEvent.Await()
        ExplosiveQueue.Offer(Explosive)

    # Make the player invulnerable for a duration
    SpawnInvulnerability(Player : player)<suspends>:void =
        PlayerDealtDamageEvent := GameEventManager.GetDealtDamageEvent(Player)
        if(FortCharacter := Player.GetFortCharacter[]):
            FortCharacter.SetVulnerability(false)
            race:
                Sleep(SpawnGenerationData.InvulnerabilityDuration)
                PlayerDealtDamageEvent.Await()
            FortCharacter.SetVulnerability(true)
