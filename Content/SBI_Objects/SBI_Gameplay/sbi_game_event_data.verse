using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }

player_spawn_pad_device_tag := class(tag){}

# Any Devices/References that involve basic Player Interactions with the environment/other players
sbi_game_event_data<public> := class<concrete>:
    # All Team Settings Device (for Spawn Events)
    @editable       AllTeamSettingsDevice<public> : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    # Respawn Delay
    @editable       RespawnDelay : float = 1.0
    # Elimination Manager
    @editable       EliminationManager<public> : elimination_manager_device = elimination_manager_device{}
    # Initialize Timer
    @editable       InitializeTimer<public> : timer_device = timer_device{}
    # Initialize SFX
    @editable       InitializeSFX<public> : audio_player_device = audio_player_device{}
    # Loading SFX
    @editable       LoadingSFX<public> : audio_player_device = audio_player_device{}
    # Use Debug
    @editable       UseDebug : logic = true