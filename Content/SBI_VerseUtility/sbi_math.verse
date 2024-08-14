using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }

Remap<public>(Value : float, InputLow : float, InputHigh : float, TargetLow : float, TargetHigh : float)<transacts>:float = 
    TargetLow + (Value - InputLow) * (TargetHigh - TargetLow) / (InputHigh - InputLow)

ConvertV2i<public>(V2F : vector2)<transacts><decides>:vector2i =
    return vector2i:
        X := Int[V2F.X]
        Y := Int[V2F.Y]

operator'*'<public>(V1 : vector2, V2 : vector2)<transacts>:vector2 =
    vector2:
        X := V1.X * V2.X
        Y := V1.Y * V2.Y

BoxToWorld<public>(Origin : vector3, Extents : vector3)<transacts>:tuple(vector3, vector3) =
    var Minimum : vector3 = Origin - Extents
    var Maximum : vector3 = Origin + Extents
    if(Minimum.Z <= 0.0):
        set Minimum.Z = 1.0
    return (Minimum, Maximum)

Abs<public>(V3 : vector3)<transacts>:vector3 =
    vector3:
        X := Abs(V3.X)
        Y := Abs(V3.Y)
        Z := Abs(V3.Z)

# Author: Ep8Script
# Parses an int from a string
(String : string).ParseInt<public>()<decides><transacts>:int=
    Characters:string = "0123456789"
    var Result:int = 0
    Sign:int = String[0] = "-" and -1 or 1
    for (Index->Char : String, Index > 0 or Sign = 1):
        CharIndex := Characters.Find[Char]
        set Result = Result * 10 + CharIndex
    Result * Sign

# Author: Steven Lacharite
# Parses a float from a string
(InString:string).ParseFloat<public>()<decides><transacts>:float=
    var ReturnFloat : float = 0.0
    var ReturnFloatAfterDecimal : float = 0.0
    var ReturnFloatFactor : float = 1.0

    if (InString.Length > 0):
        var StrippedString : string = ""
        ValidCharacters : string = "0123456789-."

        for(S : InString):
            if (ValidCharacters.Find[S] > -1):
                set StrippedString += "{S}"

        if (StrippedString[0] = '-'):
            if { Sliced :=  StrippedString.Slice[1, StrippedString.Length - 1], set StrippedString = Sliced }
            set ReturnFloatFactor = -1.0
        else:
            set ReturnFloatFactor = 1.0
        
        var ReturnFloatAfterDecimalFactor : float = 0.1        
        var UnderZero : logic = false

        for (Sc : StrippedString):
            if(Sc = '.'):
                set UnderZero = true
            else:
                if(UnderZero = true):
                    FloatAfterDecimal := ReturnFloatAfterDecimal + (ReturnFloatAfterDecimalFactor * (ValidCharacters.Find[Sc] * 1.0))
                    set ReturnFloatAfterDecimal = FloatAfterDecimal
                    set ReturnFloatAfterDecimalFactor *= 0.1
                else:
                    MyFloat := ReturnFloat * 10.0 + (ValidCharacters.Find[Sc] * 1.0)
                    set ReturnFloat = MyFloat
        
        (ReturnFloat + ReturnFloatAfterDecimal) * ReturnFloatFactor
    else:    
        ReturnFloat


Coinflip()<transacts><decides>:void =
    GetRandomInt(0, 1) = 1

# If a V1 is equal to V2 with as precise as possible accuracy
(V1 : vector3).IsEqualTo<public>(V2 : vector3)<transacts><decides>:vector3 =
    IsAlmostEqual[V1, V2, 0.0]
    return V1

# Tests if one vector is the negative of the other
(V1 : vector3).IsNegativeOf<public>(V2 : vector3)<transacts><decides>:void=
    V2.IsEqualTo[-V1]

# Set a vector to Zero
(V3 : vector3).SetToZero<public>(Axis : vector3)<transacts>:vector3 =
    Projection := DotProduct(V3, Axis) / DotProduct(Axis, Axis) * Axis
    V3 - Projection

(V2 : vector2).ToV3<public>(?Z : float = 0.0)<transacts>:vector3 = 
    vector3:
        X := V2.X
        Y := V2.Y
        Z := Z

