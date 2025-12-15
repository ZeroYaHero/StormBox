using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Playspaces }

using { SBI_Gameplay }
using { SBI_VerseUtility }


# Lobby Manager. Oversees anything in the lobby area not intended for gameplay.
sbi_lobby_manager<public> := class:
    # Center Box Responsible for Queueing Players in the "Storm Box" Gameplay Area.
    QueueBox<public> : sbi_queue_box
    # Devices used for players when they interact with the environment.
    GameEventManager<public> : sbi_game_event_manager
    # Agent To Queue Box Anims
    var AgentToQueueBoxAnims : [agent]sbi_queue_box_anim = map{}

    # Initialize the Lobby
    Initialize<public>():void =
        GameEventManager.PlayerSpawnedEvent.SubscribeEvent(OnPlayerSpawn) # ? # TODO: Maybe await instead?
        GameEventManager.PlayerLeftEvent.SubscribeEvent(OnPlayerLeave) # ? # TODO: Maybe await instead
        spawn{AnimateQueueBox()}
        SubscribeMutatorQueueBoxAnims()
        QueueBox.LogoSpriteProp.Hide()
        QueueBox.Mutator.AgentEntersEvent.Subscribe(CloseBoxForce)

    # On Player Spawn and if they do not have reference to QueueBoxAnim, attach one to their Key
    OnPlayerSpawn(Agent : agent):void =
        if:
            not AgentToQueueBoxAnims[Agent]
            QueueBoxAnim := QueueBox.Anims.Poll[]
            set AgentToQueueBoxAnims[Agent] = QueueBoxAnim
        then:
            Print("Polled Queue Box Anim, Agent now has QueueBoxAnim reference!")
        else:
            Print("AgentToQueueBoxAnims for Agent already exists, could not Poll from Queue with Length {QueueBox.Anims.Size()}, or Setting Failed (unreachable)")
        QueueBox.BoxBarrier.AddToIgnoreList(Agent)
        # spawn{ShowQueueBoxPulse(Agent)}
    
    # On Player Leave dereference/reallocate QueueBoxAnim to pool
    OnPlayerLeave(Agent : agent):void =
        if(QueueBoxAnim := AgentToQueueBoxAnims[Agent]):
            QueueBox.Anims.Offer(QueueBoxAnim)

    # Animate the Queue Box Rotation
    AnimateQueueBox()<suspends>:void =
        if(QueueBox.QueueBoxProp.IsValid[]):
            QueueBox.QueueBoxProp.MoveTo(QueueBox.QueueBoxProp.GetTransform().Translation + vector3{Z := 768.0}, IdentityRotation(), 15.0)
            # QueueBox.QueueBoxProp.MoveTo(QueueBox.QueueBoxProp.GetTransform().Translation + vector3{Z := 768.0}, MakeRotationFromYawPitchRollDegrees(180.0, 0.0, 0.0), 10.0)
            # if(AnimController := QueueBox.QueueBoxProp.GetAnimationController[]):
            #     Keyframe := keyframe_delta:
            #         DeltaLocation := vector3{}
            #         DeltaRotation := MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0)
            #         Time := QueueBox.Prop360RotationTime / 4.0
            #     Keyframes := array{Keyframe, Keyframe, Keyframe, Keyframe}
            #     AnimController.SetAnimation(Keyframes, ?Mode := animation_mode.Loop)
            #     AnimController.Play()

    # Subscribe Mutator Queue Box Anims
    SubscribeMutatorQueueBoxAnims():void =
        for: 
            Obj : GetCreativeObjectsWithTag(sbi_queue_box_anim_mutator{})
            MutatorZoneDevice := mutator_zone_device[Obj]
        do:
            TagView := MutatorZoneDevice.GetTags()
            if(TagView.Has[open_on_leave{}]):
                MutatorZoneDevice.AgentExitsEvent.Subscribe(OpenQueueBoxAnimation)
                Print("Subscribing Mutator Exit for Queue Box Open Animation")
            else if(TagView.Has[close_on_leave{}]):
                MutatorZoneDevice.AgentExitsEvent.Subscribe(CloseQueueBoxAnimation)
                Print("Subscribing Mutator Exit for Queue Box Close Animation")
            if(TagView.Has[open_on_enter{}]):
                MutatorZoneDevice.AgentEntersEvent.Subscribe(OpenQueueBoxAnimation)
                Print("Subscribing Mutator Enter for Queue Box Open Animation")
            else if(TagView.Has[close_on_enter{}]):
                MutatorZoneDevice.AgentEntersEvent.Subscribe(CloseQueueBoxAnimation)
                Print("Subscribing Mutator Enter for Queue Box Close Animation")

    # Open Queue Box Animation
    OpenQueueBoxAnimation(Agent : agent):void =
        if(QueueBoxAnims := AgentToQueueBoxAnims[Agent]):
            QueueBoxAnims.Open(Agent)
        
    # Close Queue Box Animation
    CloseQueueBoxAnimation(Agent : agent):void =
        if(QueueBoxAnims := AgentToQueueBoxAnims[Agent]):
            QueueBoxAnims.Close(Agent)

    # Animate Loading Bar
    AnimateLoadingBar<public>(StartPercentage : float, EndPercentage : float, Duration : float)<suspends>:void =
        StartTransform := transform:
            Translation := QueueBox.LoadingSpriteBarProp.GetTransform().Translation
            Rotation := IdentityRotation()
            Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0 + StartPercentage}
        if(AnimationController := QueueBox.LoadingSpriteBarProp.GetAnimationController[]):
            AnimationController.Pause()
            if { QueueBox.LoadingSpriteBarProp.TeleportTo[StartTransform] }
            DeltaScale := vector3{X := 1.0, Y := 1.0, Z := 1.0 + EndPercentage} / StartTransform.Scale
            Print("CurrentScale: {StartTransform.Scale}\nDeltaScale: {DeltaScale}\nCurrentScale x DeltaScale: {StartTransform.Scale * DeltaScale}\nEnd Percentage:{EndPercentage}")
            Keyframes := array:
                keyframe_delta:
                    DeltaLocation := vector3{}
                    DeltaRotation := IdentityRotation()
                    DeltaScale := DeltaScale
                    Time := Duration
                    Interpolation := InterpolationTypes.EaseIn
            AnimationController.SetAnimation(Keyframes, ?Mode := animation_mode.OneShot)
            AnimationController.Play()

            if(EndPercentage = 1.0):
                race:
                    Sleep(Duration)
                    AnimationController.AwaitNextKeyframe()
                HideLoadingBarShowLogo()

    # Show Pulse
    ShowQueueBoxPulse(Agent : agent)<suspends>:void =
        if(not GameEventManager.GameInitialized?):
            Print("GAME NOT INITIALIZED, WAITING FOR INITIALIZATION")
            GameEventManager.GameInitializedEvent.Await()
        Print("GAME INITIALIZED")
        race:
            loop:
                PlayerPackaged := GameEventManager.PlayerStormBoxPackagedEvent.Await()
                if(PlayerPackaged = player[Agent]):
                    Print("THIS PLAYER HAS BEEN PACKAGED")
                    break
            block:
                Sleep(QueueBox.QueueBoxPulseWait)
                Print("SHOWING PULSE")
                QueueBox.ObjectivePulseDevice.ActivateObjectivePulse(Agent)
                Sleep(Inf)
            loop:
                PlayerThatLeft := GameEventManager.PlayerLeftEvent.Await()
                if(PlayerThatLeft = player[Agent]):
                    Print("THIS PLAYER HAS LEFT")
                    break
        Print("HIDING PULSE")
        for(I := 1..20):
            QueueBox.ObjectivePulseDevice.DeactivateObjectivePulse(Agent)

    # Hide Loading Bar and Show Logo
    HideLoadingBarShowLogo<public>():void =
        QueueBox.LoadingSpriteBarProp.Hide()
        QueueBox.LogoSpriteProp.Show()

    # Close Box Force
    CloseBoxForce(Agent : agent):void =
        if(QueueBoxAnims := AgentToQueueBoxAnims[Agent]):
            QueueBoxAnims.Close(Agent, ?Force := true)
