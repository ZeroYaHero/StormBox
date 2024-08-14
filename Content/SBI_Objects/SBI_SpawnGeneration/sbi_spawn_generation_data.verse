using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }
using { /Fortnite.com/Characters }

using { SBI_StormBoxStorm }
using { SBI_Rewards }

sbi_spawn_generation_messages := module:
    # Grid Point Sampling Message
    GridPointSampling<localizes><public>: message = "Grid Point Sampling Multipliers Must Be Positive Whole Integers"

sbi_spawn_generation_data<public> := class<concrete>:
    # Attempt Delay
    @editable       AttemptDelay : float = 1.5
    # Front Fraction Volume (Spawners will spawn in the front 1/X of the Volume)
    @editable       MaxSpawnerZoneDivisor : float = 4.0
    # Minimum Spawner Zone Divisor
    @editable       MinSpawnerZoneDivisor : float = 1.5
    # Extent Tolerance
    @editable       ExtentTolerance : vector3 = vector3{X := 512.0, Y := 512.0, Z := 384.0}
    # Grid Point Sampling
    @editable:
        ToolTip := sbi_spawn_generation_messages.GridPointSampling
    GridPointSamplingMultiplier : vector3 = vector3{X := 1.0, Y := 1.0, Z := 2.0}
    # Max Spawners At Once
    @editable       MaxSpawnersAtOnce : int = 24
    # Assets neccessary for a protected spawner
    @editable       PlayerSpawnerAssets : sbi_spawn_assets = sbi_spawn_assets{}
    # Attempt count
    @editable       MaxAttemptCount : int = 30
    # Package HUD Message Device
    @editable       PackageHUDMessage : hud_message_device = hud_message_device{}
    # Shipping HUD Message Device
    @editable       ShippingHUDMessage : hud_message_device = hud_message_device{}
    # Shipped HUD Message Device
    @editable       ShippedHUDMessage : hud_message_device = hud_message_device{}
    # Extended Wait Message
    @editable       QueueWaitHUDMessage : hud_message_device = hud_message_device{}
    # Use Debug
    @editable       UseDebug : logic = false
    # Invulnerability Duration
    @editable       InvulnerabilityDuration : float = 5.0