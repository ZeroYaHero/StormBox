using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }

# Score Management
sbi_score_management<public> := class<concrete>:

    # Score Manager Device for setting score
    @editable       ScoreManagerDevice : score_manager_device = score_manager_device{}
    # Highest Score Reference Device seen in lobby
    @editable       HighestScoreReferenceDevice : player_reference_device = player_reference_device{}
    # Elimination Score Amount
    @editable       EliminationScoreAmount : int = 1
    # Score Streak Award SFX
    @editable       ScoreStreakSFX : audio_player_device = audio_player_device{}
    # Score Streaks
    @editable       var ScoreStreaks : []sbi_score_streak = array{}
    # Repeat Score Streaks
    @editable       RepeatScoreStreaks : logic = true