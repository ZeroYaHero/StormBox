using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }

using { SBI_VerseUtility }
using { SBI_StormBoxStorm }

# Item and Loot Controller
sbi_item_and_loot_controller<public> := class:
    
    # Player Interaction Manager
    GameEventManager<public> : sbi_game_event_manager
    # Item and Loot Management
    ItemAndLootManagement<public> : sbi_item_and_loot_management
    # Supply Drop Queue
    SupplyDropQueue : device_queue = device_queue{}
    # Debug Drawer
    DebugDrawer : debug_draw = debug_draw{}

    # Initialize
    Initialize<public>():void =
        SubscribeItemSaveLoad()
        BuildSupplyDropQueue()
        spawn{DisposeItemsLoop()}
        spawn{GrantMobilityHeals()}

    # Subscribe Item Save Load
    SubscribeItemSaveLoad():void =
        ItemAndLootManagement.OnItemsLoadedTrigger.TriggeredEvent.Subscribe(HandleIllegalItemsLoad)
        GameEventManager.PlayerSpawnedEvent.SubscribeEvent(HandleIllegalItemsSpawn)
        for:
            Obj : GetCreativeObjectsWithTag(load_items_button{})
            LoadItemsButton := button_device[Obj]
        do:
            LoadItemsButton.InteractedWithEvent.Subscribe(LoadItems)
        for:
            Obj : GetCreativeObjectsWithTag(save_items_button{})
            SaveItemsButton := button_device[Obj]
        do:
            SaveItemsButton.InteractedWithEvent.Subscribe(SaveItems)

    # Build Supply Drop Queue
    BuildSupplyDropQueue():void =
        for(Obj : GetCreativeObjectsWithTag(supply_drop_device_tag{}), SupplyDropSpawner := supply_drop_spawner_device[Obj]):
            SupplyDropQueue.Offer(SupplyDropSpawner)
            spawn{AwaitSupplyDropOpen(SupplyDropSpawner)}
            
    # Load Items for this Agent
    LoadItems(Agent : agent):void =
        if(ItemAndLootManagement.UseDebug?):
            Print("Loading Items for Agent")
        ItemAndLootManagement.LoadItemsTrigger.Trigger(Agent)
        ItemAndLootManagement.LoadedItemsHUD.Show(Agent)

    # Save Items for this Agent
    SaveItems(Agent : agent):void =
        if(ItemAndLootManagement.UseDebug?):
            Print("Saving Items for Agent")
        ItemAndLootManagement.SaveItemsTrigger.Trigger(Agent)
        ItemAndLootManagement.SavedItemsHUD.Show(Agent)

    # Handle Illegal Items that may have been saved/loaded for this agent
    HandleIllegalItemsLoad(MaybeAgent : ?agent):void =
        if(Agent := MaybeAgent?):
            for:
                Obj : GetCreativeObjectsWithTag(illegal_item_load_remover{})
                IllegalItemRemover := item_remover_device[Obj]
            do:
                IllegalItemRemover.Remove(Agent)

    # Handle Illegal Items Spawn
    HandleIllegalItemsSpawn(Player : player):void =
        Print("Removing Illegal Items Spawn")
        for:
            Obj : GetCreativeObjectsWithTag(illegal_item_spawn_remover{})
            IllegalItemRemover := item_remover_device[Obj]
        do:
            IllegalItemRemover.Remove(Player)

    # Dispose Items Loop
    DisposeItemsLoop()<suspends>:void =
        loop:
            ItemAndLootManagement.LobbyMutatorDisposal.Disable()
            Sleep(ItemAndLootManagement.LobbyItemLifetime)
            ItemAndLootManagement.LobbyMutatorDisposal.Enable()
            Sleep(0.1)

    # Await Storm Phase Selection
    AwaitStormPhaseSelection<public>(StormBoxController : storm_box_controller)<suspends>:void =
        loop:
            SelectedStormPhase := StormBoxController.StormPhaseSelectedEvent.Await()
            if(ItemAndLootManagement.UseDebug?):
                DebugDrawer.Clear()
            StormLocation := StormBoxController.GetStormLocation()
            PhaseLocation := SelectedStormPhase.Location
            LocationPhaseDistance := DistanceXY(StormLocation, PhaseLocation)
            for(I := 1..ItemAndLootManagement.SupplyDropSpawnAttemptCount):
                SupplyDropRandomProbability := GetRandomFloat(0.0, 1.0)
                if(SupplyDropRandomProbability <= ItemAndLootManagement.SupplyDropSpawnProbability):
                    if(SupplyDropSpawner := supply_drop_spawner_device[SupplyDropQueue.Poll[]]):
                        RandomSupplyDropSpawnerPoint := vector3:
                            X := Abs(SelectedStormPhase.Axis.NormalDirection).IsEqualTo[vector3{X := 1.0}] and
                            GetRandomFloat(LocationPhaseDistance / 1.5, LocationPhaseDistance) * SelectedStormPhase.Axis.NormalDirection.X + StormLocation.X or 
                            GetRandomFloat(-StormBoxController.StormBoxData.Extents.X, StormBoxController.StormBoxData.Extents.X) + PhaseLocation.X
                            Y := Abs(SelectedStormPhase.Axis.NormalDirection).IsEqualTo[vector3{Y := 1.0}] and
                            GetRandomFloat(LocationPhaseDistance / 1.5, LocationPhaseDistance) * SelectedStormPhase.Axis.NormalDirection.Y + StormLocation.Y or
                            GetRandomFloat(-StormBoxController.StormBoxData.Extents.Y, StormBoxController.StormBoxData.Extents.Y) + PhaseLocation.Y
                            Z := 8000.0
                        if(ItemAndLootManagement.UseDebug?):
                            DebugDrawer.DrawBox(RandomSupplyDropSpawnerPoint, IdentityRotation(), ?Extent := vector3{X := 20.0, Y := 20.0, Z := 20.0}, ?Color := NamedColors.Purple, ?Thickness := 10.0, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                        if(SupplyDropSpawner.TeleportTo[RandomSupplyDropSpawnerPoint, IdentityRotation()]):
                            SupplyDropSpawner.Spawn()
                        else if(ItemAndLootManagement.UseDebug?):
                            Print("WARNING: Failed to Teleport Supply Drop Spawner.")
                    else if(ItemAndLootManagement.UseDebug?):
                        Print("WARNING: Failed to Poll Supply Drop Spawner from Queue, none are expired or Queue is never initialized")

    # Await Supply Drop Open
    AwaitSupplyDropOpen(SupplyDropSpawner : supply_drop_spawner_device)<suspends>:void =
        loop:
            race:
                block:
                    SupplyDropSpawner.LandingEvent.Await()
                    Sleep(ItemAndLootManagement.SupplyDropExpirationTime)
                SupplyDropSpawner.OpenedEvent.Await()
            SupplyDropQueue.Offer(SupplyDropSpawner)

    # Grant Mobility Heals
    GrantMobilityHeals()<suspends>:void =
        loop:
            Player := GameEventManager.PlayerStormBoxShippedEvent.Await()
            ItemAndLootManagement.ResourcesGranter.GrantItem(Player)
            ItemAndLootManagement.ShieldHealMobilityUtilityGranter.CycleToRandomItem(Player)