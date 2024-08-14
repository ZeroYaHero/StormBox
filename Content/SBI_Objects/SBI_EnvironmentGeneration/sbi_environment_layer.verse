using { /UnrealEngine.com/Temporary/SpatialMath }

# Environment Layer
sbi_environment_layer<public> := class:
    # XYZ Coordinate Offset
    XYZCoordinateOffset<public> : vector3 # Z represent the ZLayer, XY represent offset from the coordinate.
    # Terrain Noise Threshold for Terrain Spawn
    TerrainNoiseThreshold<public> : float