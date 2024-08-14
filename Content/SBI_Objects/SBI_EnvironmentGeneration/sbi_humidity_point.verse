using { /UnrealEngine.com/Temporary/SpatialMath }

# Humidity Point for the biome Voroni Diagaram
sbi_humidity_point<public> := class:
    # Location (Z does not really matter)
    Location<public> : vector3
    # The level of humidity (normalized range)
    HumidityLevel<public> : float