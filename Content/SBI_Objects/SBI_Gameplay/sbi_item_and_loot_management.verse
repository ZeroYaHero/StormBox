using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }

using { SBI_EnvironmentGeneration }
using { SBI_VerseUtility }
using { SBI_StormBoxStorm }
using { SBI_Gameplay }

# Supply Drop Device
supply_drop_device_tag := class(tag){}
# Button Device to Prompt Loading Saved Items
load_items_button := class(tag){}
# Button Device to Prompt Saving Current Items
save_items_button := class(tag){}
# Remover for any items that we don't want players to save/load.
illegal_item_load_remover := class(tag){}
# Remover for any items that we don't want the players to spawn with.
illegal_item_spawn_remover := class(illegal_item_load_remover){}

# Carries any references related to items/loadouts
sbi_item_and_loot_management<public> := class<concrete>:
    # Trigger for Loading Items/Loadout via Save Point Device
    @editable       LoadItemsTrigger<public> : trigger_device = trigger_device{}
    # Trigger for Saving Items/Loadout via Save Point Device
    @editable       SaveItemsTrigger<public> : trigger_device = trigger_device{}
    # Triggered when any Player has Items Loaded via Save Point Device
    @editable       OnItemsLoadedTrigger<public> : trigger_device = trigger_device{}
    # Saved Items HUD
    @editable       SavedItemsHUD<public> : hud_message_device = hud_message_device{}
    # Loaded Items HUD
    @editable       LoadedItemsHUD<public> : hud_message_device = hud_message_device{}
    # Mutator Zone Responsible for Disposing Items after x Lifetime
    @editable       LobbyMutatorDisposal<public> : mutator_zone_device = mutator_zone_device{}
    # Lobby Item Lifetime before Disposal
    @editable       LobbyItemLifetime<public> : float = 15.0
    # Supply Drop Spawn Chance
    @editable       SupplyDropSpawnProbability<public>: normalized_range = 0.125
    # Supply Drop Attempt Count
    @editable       SupplyDropSpawnAttemptCount<public> : int = 3
    # Heal and Mobility Granter
    @editable       ShieldHealMobilityUtilityGranter<public> : item_granter_device = item_granter_device{}
    # Resources Granter
    @editable       ResourcesGranter<public> : item_granter_device = item_granter_device{}
    # Supply Drop Expiration Time
    @editable       SupplyDropExpirationTime<public> : float = 300.0
    # Use Debug
    @editable       UseDebug : logic = false