
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

using { SBI_Objects.SBI_StormBoxStorm }
using { SBI_Objects.SBI_Lobby }
using { SBI_Objects.SBI_Rewards }
using { SBI_Objects.SBI_SpawnGeneration }
using { SBI_Objects.SBI_EnvironmentGeneration }
using { SBI_Objects.SBI_Gameplay }

# A Verse-authored creative device that can be placed in a level
sbi_main_device := class(creative_device):

    @editable       EnvironmentGenerationData : sbi_environment_generation_data = sbi_environment_generation_data{}

    @editable       SpawnGenerationData : sbi_spawn_generation_data = sbi_spawn_generation_data{}

    @editable       StormBoxData : storm_box_data = storm_box_data{}

    @editable       GameEventData : sbi_game_event_data = sbi_game_event_data{}

    @editable       ItemAndLootManagement : sbi_item_and_loot_management = sbi_item_and_loot_management{}

    @editable       ScoreManagement : sbi_score_management = sbi_score_management{}

    @editable       QueueBox : sbi_queue_box = sbi_queue_box{}

    @editable       RewardCollection : sbi_reward_collection = sbi_reward_collection{}

    @editable       CameraManagement : sbi_camera_management = sbi_camera_management{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void =
        Print("===============================================")
        InitializeGame()

    InitializeGame()<suspends>:void = 
        GameEventManager := sbi_game_event_manager:
            GameEventData := GameEventData
            FortPlayspace := GetPlayspace()
        GameEventManager.Initialize()
        Print("Game Event Manager Initialized")

        ItemAndLootController := sbi_item_and_loot_controller:
            GameEventManager := GameEventManager
            ItemAndLootManagement := ItemAndLootManagement
        ItemAndLootController.Initialize()
        Print("Item and Loot Controller Initialized")

        LobbyManager := sbi_lobby_manager:
            QueueBox := QueueBox
            GameEventManager := GameEventManager
        LobbyManager.Initialize()
        Print("Lobby Manager Initialized")

        CameraSpectator := sbi_camera_spectator:
            GameEventManager := GameEventManager
            CameraManagement := CameraManagement
        CameraSpectator.Initialize()
        Print("Camera Spectator Initialized")

        spawn{LobbyManager.AnimateLoadingBar(0.0, 0.1, 1.0)}
        EnvironmentGenerationData.Compile()
        Print("Environment Generation Data Compiled")

        spawn{LobbyManager.AnimateLoadingBar(0.1, 0.9, 30.0)}

        EnvironmentGenerator := sbi_environment_generator:
            EnvironmentGenerationData := EnvironmentGenerationData
        sync:
            EnvironmentGenerator.Initialize()
            block:
                EnvironmentGenerationData.AllChunksFloorGeneratedEvent.Await()
                CameraSpectator.AllSpectate()
        Print("Environment Generator Initialized")

        spawn{LobbyManager.AnimateLoadingBar(0.9, 1.0, 1.0)}
        StormBoxController := storm_box_controller:
            StormBoxData := StormBoxData
            GameEventManager := GameEventManager
            StormBoxPhaseReward := RewardCollection.StormBoxPhaseReward
        StormBoxController.GenerateStorm()
        Print("Storm Box Controller Generated")

        SpawnGenerator := sbi_spawn_generator:
            SpawnGenerationData := SpawnGenerationData
            StormBoxController := StormBoxController
            QueueBox := QueueBox
            PackageReward := RewardCollection.PackageReward
            ShipReward := RewardCollection.ShipReward
            GameEventManager := GameEventManager
        SpawnGenerator.Initialize()
        Print("Spawn Generator Initialized")

        ScoreController := sbi_score_controller:
            ScoreManagement := ScoreManagement
            GameEventManager := GameEventManager
        ScoreController.Initialize()

        spawn{ItemAndLootController.AwaitStormPhaseSelection(StormBoxController)}
        spawn{StormBoxController.StormLoop()}

        GameEventManager.GameInitializedEvent.Signal()

    # TODO: This could be else where.

