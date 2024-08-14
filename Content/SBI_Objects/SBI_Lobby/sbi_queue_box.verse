using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }


# Queue Box Animation Object
sbi_queue_box_anim<public> := class<concrete>:
    # Open Animation Cinematic Sequence Device
    @editable       OpenAnimation : cinematic_sequence_device = cinematic_sequence_device{}
    # Close Animation Cinematic Sequence Device
    @editable       CloseAnimation : cinematic_sequence_device = cinematic_sequence_device{}
    # If the object is last opened
    var IsOpen : logic = false
    
    # Open the Queue Box for Agent
    Open(Agent : agent, ?Force : logic = false):void =
        if(not IsOpen? or Force?):
            set IsOpen = true
            CloseAnimation.GoToEndAndStop(Agent)
            OpenAnimation.Play(Agent)

    # Close the Queue Box for Agent
    Close(Agent : agent, ?Force : logic = false):void =
        if(IsOpen? or Force?):
            set IsOpen = false
            OpenAnimation.GoToEndAndStop(Agent)
            CloseAnimation.Play(Agent)

# Queue Box Animation Collection (its a Queue)
sbi_queue_box_anim_collection<public> := class<concrete>(queue_interface(sbi_queue_box_anim)):

    @editable       var Elements : []sbi_queue_box_anim = array{}

    Offer<override>(Element : sbi_queue_box_anim):void =
        set Elements += array{Element}

    Poll<override>()<transacts><decides>:sbi_queue_box_anim =
        Polled := Elements[0]
        Removed := Elements.RemoveElement[0]
        set Elements = Removed
        Polled

    Size<override>():int =
        Elements.Length

    IsEmpty<override>()<transacts><decides>:void =
        Elements.Length < 0

# Queue Box Anim Mutator Tags
sbi_queue_box_anim_mutator := class(tag){}
    open_on_leave := class(sbi_queue_box_anim_mutator){}
    open_on_enter := class(sbi_queue_box_anim_mutator){}
    close_on_leave := class(sbi_queue_box_anim_mutator){}
    close_on_enter := class(sbi_queue_box_anim_mutator){}

# Queue Box Encapsulation for the bridge between the Lobby and "Storm Box"
sbi_queue_box<public> := class<concrete>:
    # Parent Prop
    @editable       QueueBoxProp<public> : creative_prop = creative_prop{}
    # Mutator for when a Player is "in"
    @editable       Mutator<public> : mutator_zone_device = mutator_zone_device{}
    # Outer Queue Barrier for Preventing Players from Jumping In
    @editable       OuterQueueBarrier<public> : barrier_device = barrier_device{}
    # Box Barrier for Blocking Camera/Preventing Players from Jumping Out
    @editable       BoxBarrier<public> : barrier_device = barrier_device{}
    # Prop360 Rotation Time
    @editable       Prop360RotationTime<public> : float = 20.0
    # Animations
    @editable       Anims<public> : sbi_queue_box_anim_collection = sbi_queue_box_anim_collection{}
    # Loading Sprite Bar Prop
    @editable       LoadingSpriteBarProp<public> : creative_prop = creative_prop{}
    # Logo Sprite Prop
    @editable       LogoSpriteProp<public> : creative_prop = creative_prop{}
    # Shutter Prop Control
    @editable       ShutterAnimationPropControl<public> : creative_prop = creative_prop{}
    # Object Pulse
    @editable       ObjectivePulseDevice<public> : objective_device = objective_device{}
    # How long to wait for queue box pulse
    @editable       QueueBoxPulseWait<public> : float = 10.0

