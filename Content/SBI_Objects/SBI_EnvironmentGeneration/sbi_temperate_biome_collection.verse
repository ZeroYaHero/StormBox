using { /Verse.org/Simulation }

sbi_temperate_biome_collection<public> := class<concrete>():

    @editable       TemperateName : string = ""

    @editable       Weighting : float = 1.0

    @editable       Biomes : []sbi_environment_biome = array{}

    var NormedWeighting : float = 0.0

    CalculateBiomeWeights():void =
        var BiomeWeightSum : float = 0.0
        for(Biome : Biomes):
            Biome.CalculateMaterialWeights()
            set BiomeWeightSum += Biome.Weighting

        for(Biome : Biomes):
            if(Biome.Weighting = BiomeWeightSum):
                set Biome.NormedWeighting = 1.0
            else:
                set Biome.NormedWeighting = Biome.Weighting / BiomeWeightSum