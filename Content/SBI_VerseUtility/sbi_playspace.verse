using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }

EliminateAgent<public>(Agent : agent):void =
    if(FortCharacter := Agent.GetFortCharacter[]):
        FortCharacter.Damage(500.0)
    else:
        Print("Failed to get fort_character to Eliminate")