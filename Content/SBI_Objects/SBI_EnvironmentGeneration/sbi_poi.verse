using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }

sbi_simple_poi<public> := class<concrete>:

    @editable       Prop : creative_prop = creative_prop{}

    @editable       FreeRotation : logic = false

    @editable       SpawnOffsetMaximumRange : float = 16.0


    PlacePOI(GroundSafeGridPoint : sbi_grid_point):void =
        POIRotation := FreeRotation? and MakeRotationFromYawPitchRollDegrees(GetRandomFloat(0.0, 360.0), 0.0, 0.0) or MakeRotationFromYawPitchRollDegrees(GetRandomInt(0, 3) * 90.0, 0.0, 0.0)
        Offset := FreeRotation? and POIRotation.GetLocalForward() * GetRandomFloat(0.0, SpawnOffsetMaximumRange) or vector3{}
        Translation := GroundSafeGridPoint.Location + Offset

        Transform := transform:
            Translation := Translation
            Rotation := POIRotation
            Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0}

        if(Prop.TeleportTo[Transform]):
            GroundSafeGridPoint.AddPOI(Self)
        else:
            Print("WARNING: Failed to place POI")

