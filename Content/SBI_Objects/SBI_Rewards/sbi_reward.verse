using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/AI }

# Simple Encapsulation for when we want to "Reward" a Player for something.
sbi_reward<public> := class<concrete>:
    # Reward Gold
    @editable       ItemGranter<public> : ?item_granter_device = false
    # Reward XP
    @editable       Accolade<public> : ?accolades_device = false
    # Show a HUD Message to represent the Reward
    @editable       HUDMessageDevice<public> : ?hud_message_device = false
    # Show a Message in the Feed to announce the Reward
    @editable       MessageFeedDevice<public> : ?elimination_feed_device = false
    # For backend analytics
    @editable       AnalyticsDevice<public> : ?analytics_device = false

    # Reward the Agent
    Reward<public>(Agent : agent):void =
        if(XP := Accolade?) { XP.Award(Agent) }
        if(Item := ItemGranter?) { Item.GrantItem(Agent) }
        if(HUD := HUDMessageDevice?) { HUD.Show(Agent) }
        if(MessageFeed := MessageFeedDevice?) { MessageFeed.Activate(Agent) }
        if(Analytics := AnalyticsDevice?) { Analytics.Submit(Agent) }