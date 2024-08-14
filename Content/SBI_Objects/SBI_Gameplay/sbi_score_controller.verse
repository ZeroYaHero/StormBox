using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }

using { SBI_Lobby }


# ! # TODO: Rename to Score Streak Controller
# Score Controller
sbi_score_controller<public> := class:

    # Score Management
    ScoreManagement<public> : sbi_score_management
    # Game Event Manager
    GameEventManager<public> : sbi_game_event_manager

    # Initialize the Score Controller
    Initialize<public>():void =
        spawn{AwaitStormBoxShippedEvent()}

    # Await Storm Box Shipped Event
    AwaitStormBoxShippedEvent()<suspends>:void =
        loop:
            Player := GameEventManager.PlayerStormBoxShippedEvent.Await()
            spawn{AwaitPlayerScoreEvents(Player)}

    # Await any score events for this Player 
    AwaitPlayerScoreEvents(Player : player)<suspends>:void =
        DealtEliminationEvent := GameEventManager.GetDealtEliminationEvent(Player)
        var CurrentScoreStreak : sbi_score_streak = sbi_score_streak{}
        race:
            if(FortCharacter := Player.GetFortCharacter[]):
                FortCharacter.EliminatedEvent().Await()
            block:
                loop:
                    for(ScoreStreak : ScoreManagement.ScoreStreaks):
                        set CurrentScoreStreak = ScoreStreak
                        ScoreStreak.ShowScoreStreak(Player, 0)
                        for(ScoreCount := 1..ScoreStreak.ScoreGoal): # ? In the future this could be changed to include a sync waiting for any score event.
                            DealtEliminationEvent.Await()
                            SetScore(Player, GetCurrentScore(Player) + ScoreManagement.EliminationScoreAmount)
                            MaybeHighestScoreAgent := ScoreManagement.HighestScoreReferenceDevice.GetAgent()
                            if(not MaybeHighestScoreAgent? or GetCurrentScore(Player) > GetCurrentScore(MaybeHighestScoreAgent?)):
                                ScoreManagement.HighestScoreReferenceDevice.Register(Player)
                            ScoreStreak.ShowScoreStreak(Player, ScoreCount)
                        ScoreManagement.ScoreStreakSFX.Play(Player)
                        ScoreStreak.HideScoreStreak(Player)
                        ScoreStreak.Grant(Player)
                    if(not ScoreManagement.RepeatScoreStreaks?):
                        break
                Sleep(Inf)
        CurrentScoreStreak.HideScoreStreak(Player)
        # ! # TODO: NEW NO SCORE RESET

    # Get Current Score for Agent
    GetCurrentScore(Agent : agent)<transacts>:int = 
        ScoreManagement.ScoreManagerDevice.GetCurrentScore(Agent)

    # Set Score
    SetScore(Agent : agent, Score : int):void =
        ScoreManagement.ScoreManagerDevice.SetScoreAward(Score)
        ScoreManagement.ScoreManagerDevice.Activate(Agent)