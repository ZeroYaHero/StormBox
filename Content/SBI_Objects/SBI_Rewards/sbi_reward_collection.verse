using { /Verse.org/Simulation }

# Reward Collection
sbi_reward_collection<public> := class<concrete>:
    # Reward Granted when IN the Storm Box and a Storm Phase passes
    @editable       StormBoxPhaseReward<public> : sbi_reward = sbi_reward{}
    # Reward Granted when Packaged/Queued to Enter the Storm Box
    @editable       PackageReward<public> : sbi_reward = sbi_reward{}
    # Reward Granted when Shipped/Entered the Storm Box
    @editable       ShipReward<public> : sbi_reward = sbi_reward{}
    # Reward Granted when achieve Elimination
    @editable       EliminationReward<public> : sbi_reward = sbi_reward{}
