using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices }

sbi_environment_biome := class<concrete>():

    @editable       BiomeName : string = ""

    @editable       Weighting : float = 1.0

    @editable       MaterialProbability : normalized_range = 0.6

    @editable       POIProbability : normalized_range = 0.04

    @editable       MaterialPieces : []sbi_material_piece = array{}

    @editable       var POIs : []sbi_simple_poi = array{}

    var NormedWeighting : float = 0.0

    var MaterialPieceSum : float = 0.0

    TerrainMaterial : material = SBI_BiomeMaterials.MI_OakGreenTerrain

    # Initialize this biome.
    CalculateMaterialWeights()<transacts>:void =
        for(MaterialPiece : MaterialPieces):
            set MaterialPieceSum += MaterialPiece.Weighting

    # Get a random material piece.
    GetMaterialPiece()<transacts>:?sbi_material_piece =
        var RandomWeight : float = GetRandomFloat(0.0, MaterialPieceSum)
        for(MaterialPiece : MaterialPieces):
            if(RandomWeight < MaterialPiece.Weighting):
                return option{MaterialPiece}
            else:
                set RandomWeight -= MaterialPiece.Weighting
        return false

    # Get POI Prop.
    GetPOI()<transacts>:?sbi_simple_poi =
        if:
            POI := POIs[0]
            POIRemoved := POIs.RemoveElement[0]
        then:
            set POIs = POIRemoved
            return option{POI}
        return false
