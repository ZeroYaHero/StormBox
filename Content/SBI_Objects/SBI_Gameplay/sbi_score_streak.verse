using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }

# Score Streak
sbi_score_streak := class<concrete>():
    # Score Goal
    @editable       ScoreGoal : int = 0
    # HUD Message Device
    @editable       HUDMessageDevice : hud_message_device = hud_message_device{}
    # Accolade / XP
    @editable       Accolade : accolades_device = accolades_device{}
    # Item Granter
    @editable       ItemGranter : ?item_granter_device = option{item_granter_device{}}
    # Message Feed Device
    @editable       MessageFeedDevice : elimination_feed_device = elimination_feed_device{}

    # Show Score Streak HUD to Agent
    ShowScoreStreak(Agent : agent, Progress : int):void =
        HUDMessageDevice.Show(Agent, ProgressMessage(Progress, ScoreGoal))

    # Hide Score Streak
    HideScoreStreak(Agent : agent):void =
        HUDMessageDevice.Show(Agent, ProgressMessage(0, ScoreGoal), ?DisplayTime := 0.1)

    # Grant Score Streak
    Grant(Agent : agent):void =
        Accolade.Award(Agent)
        MessageFeedDevice.Activate(Agent)
        if(Item := ItemGranter?) { Item.GrantItem(Agent) }

    # Progress Message
    ProgressMessage<localizes>(Progress : int, Goal : int):message = "{Progress}/{Goal}"