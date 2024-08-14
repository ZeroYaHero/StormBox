using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Playspaces }

using { SBI_Gameplay } 

sbi_prop_rotator := class<concrete>:

    @editable       PropParent : creative_prop = creative_prop{}

    @editable       RotateTime : float = 20.0

    Rotate():void =
        if(AnimController := PropParent.GetAnimationController[]):
            Keyframe := keyframe_delta:
                DeltaLocation := vector3{}
                DeltaRotation := MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0)
                Time := RotateTime * 0.25
            Keyframes := array{Keyframe, Keyframe, Keyframe, Keyframe}
            AnimController.SetAnimation(Keyframes, ?Mode := animation_mode.Loop)
            AnimController.Play()

sbi_camera := class<concrete>:

    @editable       Device : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable       TimeActive : float = 5.0

    @editable       OptionalRotator : ?sbi_prop_rotator = false

    @editable       Priority : int = 0

sbi_camera_management<public> := class<concrete>:

    @editable       EnvironmentCameraCycle : []sbi_camera = array{}

    var HighestPriorityCamera : sbi_camera = sbi_camera{}

    @editable       ExitButtonSize : vector2 = vector2{X := 400.0, Y := 115.0}

    @editable       ButtonAnchor : vector2 = vector2{X := 0.5, Y := 0.8}

    @editable       CameraSpectateClass : class_and_team_selector_device = class_and_team_selector_device{}

    @editable       DefaultClass : class_and_team_selector_device = class_and_team_selector_device{}

    ButtonText<localizes>:message = "Stop Watching"


sbi_camera_spectator<public> := class:

    GameEventManager<public> : sbi_game_event_manager

    CameraManagement<public> : sbi_camera_management



    Initialize<public>():void =
        for(Camera : CameraManagement.EnvironmentCameraCycle):
            if(Rotator := Camera.OptionalRotator?):
                Rotator.Rotate()
            if(Camera.Priority > CameraManagement.HighestPriorityCamera.Priority):
                set CameraManagement.HighestPriorityCamera = Camera

    AllSpectate<public>():void =
        if(CameraManagement.EnvironmentCameraCycle.Length > 0):
            for(Player : GameEventManager.GetPlayers()):
                spawn{Spectate(Player)}

    Spectate(Player : player)<suspends>:void =
        if(PlayerUI := GetPlayerUI[Player]):

            StopWatchingButton := button_quiet:
                DefaultText := CameraManagement.ButtonText

            StopWatchingColorBlock := color_block:
                DefaultOpacity := 0.0
                DefaultDesiredSize := CameraManagement.ExitButtonSize

            ButtonOverlay := overlay:
                Slots := array:
                    overlay_slot:
                        Widget := StopWatchingColorBlock
                    overlay_slot:
                        Widget := StopWatchingButton
                        HorizontalAlignment := horizontal_alignment.Fill
                        VerticalAlignment := vertical_alignment.Fill

            ButtonCanvas := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := ButtonOverlay
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        Anchors := anchors{Minimum := CameraManagement.ButtonAnchor, Maximum := CameraManagement.ButtonAnchor}

            PlayerUI.AddWidget(ButtonCanvas, player_ui_slot{InputMode := ui_input_mode.All})
            CameraManagement.CameraSpectateClass.ChangeClass(Player)
            
            race:
                StopWatchingButton.OnClick().Await()
                block:
                    GameEventManager.GameInitializedEvent.Await()
                    Sleep(5.0)
                loop:
                    for(Camera : CameraManagement.EnvironmentCameraCycle):
                        if(not GameEventManager.GameInitialized?):
                            Camera.Device.AddTo(Player)
                            race:
                                Sleep(Camera.TimeActive)
                                GameEventManager.GameInitializedEvent.Await()
                        else:
                            CameraManagement.HighestPriorityCamera.Device.AddTo(Player)
                            Sleep(Inf)

            PlayerUI.RemoveWidget(ButtonCanvas)
            CameraManagement.DefaultClass.ChangeClass(Player)

            for(Camera : CameraManagement.EnvironmentCameraCycle):
                Camera.Device.RemoveFrom(Player)