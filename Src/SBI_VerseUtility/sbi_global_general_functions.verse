using { /Fortnite.com/Devices }

# Spawn Prop Result To String
ToString<public>(Result : spawn_prop_result):string =
    case(Result):
        spawn_prop_result.Ok =>
            "Ok"
        spawn_prop_result.UnknownError =>
            "UnknownError"
        spawn_prop_result.InvalidSpawnPoint =>
            "InvalidSpawnPoint"
        spawn_prop_result.SpawnPointOutOfBounds =>
            "SpawnPointOutOfBounds"
        spawn_prop_result.InvalidAsset =>
            "InvalidAsset"
        spawn_prop_result.TooManyProps =>
            "TooManyProps"