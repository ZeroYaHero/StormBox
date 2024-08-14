using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Storm box SFX wrapper.
storm_box_sfx<public> := class<concrete>():

    # Damage SFX
    @editable       Damage : audio_player_device = audio_player_device{}
    # Still Edge
    @editable       StillEdge : creative_prop_asset = DefaultCreativePropAsset
    # Moving Edge
    @editable       MovingEdge : creative_prop_asset = DefaultCreativePropAsset