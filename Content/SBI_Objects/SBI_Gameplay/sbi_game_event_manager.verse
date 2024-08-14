using { /Verse.org/Simulation }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }

using { SBI_StormBoxStorm }
using { SBI_EnvironmentGeneration }

# Player Interaction Manager
sbi_game_event_manager<public> := class:

    # Player Interaction Data
    GameEventData<public> : sbi_game_event_data
    # Fort Playspace
    FortPlayspace<public> : fort_playspace
    # Is Game Initialized
    var <private>GameInitialized<public> : logic = false
    # -------------- Events --------------
    GameInitializedEvent<public> : event() = event(){}

    PlayerStormBoxPackagedEvent<public> : event(player) = event(player){}

    PlayerStormBoxShippedEvent<public> : event(player) = event(player){}

    PlayerSpawnedEvent<public> : event(player) = event(player){}

    PlayerLeftEvent<public> : event(player) = event(player){}

    PlayerEliminationEvent<public> : event(player) = event(player){}

    PlayerEliminatedEvent<public> : event(player) = event(player){}
    
    var PlayerDealtDamageEvent : [player]event(tuple(player, float)) = map{}

    var PlayerDealtEliminationEvent : [player]event() = map{}

    var ShippedPlayers : []player = array{}

    DebugDrawer : debug_draw = debug_draw{}

    # Initialize
    Initialize<public>():void =
        GameEventData.InitializeTimer.Start()
        GameEventData.LoadingSFX.Play()
        GameEventData.AllTeamSettingsDevice.TeamMemberSpawnedEvent.Subscribe(OnTeamMemberSpawned)
        FortPlayspace.PlayerRemovedEvent().Subscribe(OnFortPlayerLeave)
        GameEventData.EliminationManager.EliminationEvent.Subscribe(OnElimination)
        GameEventData.EliminationManager.EliminatedEvent.Subscribe(OnEliminated)
        spawn{AwaitGameInitialized()}
        spawn{AwaitStormBoxShipped()}
        # spawn{RespawnEliminatedPlayers()}

    # Could be temp
    GetPlayers<public>()<transacts>:[]player = 
        return FortPlayspace.GetPlayers()

    IsShipped<public>(Player : player)<transacts><decides>:void =
        ShippedPlayers.Find[Player]

    # Get Dealt Damage Event
    GetDealtDamageEvent<public>(Player : player):event(tuple(player, float)) =
        var NewDealtDamageEvent : event(tuple(player, float)) = event(tuple(player, float)){}
        if(DealtDamageEvent := PlayerDealtDamageEvent[Player]):
            return DealtDamageEvent
        else if(FortCharacter := Player.GetFortCharacter[], set PlayerDealtDamageEvent[Player] = NewDealtDamageEvent):
            FortCharacter.DamagedEvent().Subscribe(OnFortCharacterDamageAny)
            FortCharacter.DamagedShieldEvent().Subscribe(OnFortCharacterDamageAny)
        else if(GameEventData.UseDebug?):
            Print("WARNING: PlayerDealtDamageEvent could NOT be set")
        return NewDealtDamageEvent

    # Dealt Elimination
    GetDealtEliminationEvent<public>(Player : player):event() =
        var NewDealtEliminationEvent : event() = event(){}
        if(DealtEliminationEvent := PlayerDealtEliminationEvent[Player]):
            return DealtEliminationEvent
        else if { set PlayerDealtEliminationEvent[Player] = NewDealtEliminationEvent }
        else if(GameEventData.UseDebug?):
            Print("WARNING: PlayerDealtEliminationEvent could NOT be set")
        return NewDealtEliminationEvent

    # On Team Member Spawned
    OnTeamMemberSpawned(Agent : agent):void =
        if(Player := player[Agent]):
            PlayerSpawnedEvent.Signal(Player)

    # On Fort Player Leave
    OnFortPlayerLeave(Player : player):void =
        PlayerLeftEvent.Signal(Player)

    # On Fort Character Damaged
    OnFortCharacterDamageAny(DamageResult : damage_result):void =
        if:
            DamageRecieverPlayer := player[fort_character[DamageResult.Target].GetAgent[]]
            DamageInstigatorPlayer := player[fort_character[DamageResult.Instigator?].GetAgent[]]
        then:
            DealtDamageEvent := GetDealtDamageEvent(DamageInstigatorPlayer)
            DealtDamageEvent.Signal(DamageRecieverPlayer, DamageResult.Amount)
    

    # On Elimination
    OnElimination(MaybeAgent : ?agent):void =
        if(Player := player[MaybeAgent?]):
            PlayerEliminationEvent.Signal(Player)
            if(DealtEliminationEvent := PlayerDealtEliminationEvent[Player]):
                DealtEliminationEvent.Signal()

    # On Eliminated
    OnEliminated(Agent : agent):void =
        if(Player := player[Agent]):
            PlayerEliminatedEvent.Signal(Player)
            StormBoxPlayerRemoved := ShippedPlayers.RemoveAllElements(Player)
            set ShippedPlayers = StormBoxPlayerRemoved

    # Respawn Eliminated Players
    RespawnEliminatedPlayers()<suspends>:void =
        loop:
            for(Obj : GetCreativeObjectsWithTag(player_spawn_pad_device_tag{}), PlayerSpawnPad := player_spawner_device[Obj]):
                EliminatedPlayer := PlayerEliminatedEvent.Await()
                spawn{RespawnPlayer(EliminatedPlayer, PlayerSpawnPad)}

    # Respawn Player
    RespawnPlayer(EliminatedPlayer : player, PlayerSpawnPad : player_spawner_device)<suspends>:void =
        Sleep(GameEventData.RespawnDelay)
        RespawnLocation := PlayerSpawnPad.GetTransform().Translation + vector3{Z := 75.0}
        EliminatedPlayer.Respawn(RespawnLocation, PlayerSpawnPad.GetTransform().Rotation)

    AwaitStormBoxShipped()<suspends>:void = 
        loop:
            ShippedPlayer := PlayerStormBoxShippedEvent.Await()
            set ShippedPlayers += array{ShippedPlayer}

    # Await Game Initialized
    AwaitGameInitialized()<suspends>:void =
        GameInitializedEvent.Await()
        set GameInitialized = true
        GameEventData.LoadingSFX.Stop()
        GameEventData.InitializeTimer.Complete()
        GameEventData.InitializeSFX.Play()

