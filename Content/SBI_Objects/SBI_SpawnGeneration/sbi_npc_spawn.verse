# using { /Fortnite.com/Devices }
# using { /Verse.org/Simulation }
# using { /UnrealEngine.com/Temporary/SpatialMath }
# using { /Fortnite.com/Characters }

# sbi_npc_spawn := class:

#     Expired : logic = false
#     # Agent to "Spawn"
#     MaybeAgentToSpawn<public> : ?agent
#     # Reference Object
#     ReferenceObject<public> : creative_object_interface
#     # Spawn Assets
#     Assets<public> : sbi_spawn_assets
#     # MaybeExplosive
#     MaybeExplosive<public> : ?explosive_device
#     # MaybeTeleporter
#     MaybeTeleporter<public> : ?teleporter_device
#     # Spawn Location
#     SpawnLoc<public> : vector3
#     # Spawn Grid Point
#     GridPoint<public> : sbi_grid_point
#     # Agent Teleported Event
#     AgentTeleportedEvent<public> : event(tuple(agent, ?teleporter_device)) = event(tuple(agent, ?teleporter_device)){}
#     # MaybeExplosive Retired
#     ExplosiveRetiredEvent<public> : event(explosive_device) = event(explosive_device){}

#     # Initialize the floating spawner
#     Initialize():sbi_npc_spawn =
#         spawn { GenerateSpawner() }
#         Self

#     # Generate the spawner
#     GenerateSpawner()<suspends>:void =
#         SpawnTransform : transform = transform{Translation := SpawnLoc}

#         TeleportExplosive(SpawnTransform)

#         Assets.Platform.SpawnPropAt(SpawnTransform)
#         Assets.Platform.FinishedGrowEvent.Await()
        
#         Assets.OuterBox.SpawnPropAt(SpawnTransform)
#         Assets.CollisionBarrier.SpawnPropAt(SpawnTransform)

#         sync:
#             Assets.OuterBox.FinishedGrowEvent.Await()
#             Assets.CollisionBarrier.FinishedGrowEvent.Await()

#         TriggerExplosive()
#         ResetExplosive()
#         TeleportPlayer(SpawnTransform)

#         Assets.OuterBox.StartLifetime()
#         Assets.CollisionBarrier.StartLifetime()
#         if(LifetimeVal := Assets.OuterBox.OptionalLifetime?):
#             Sleep(LifetimeVal - 0.2)
#             Assets.OuterBoxWithAnim.SpawnPropAt(SpawnTransform)
#         else:
#             Assets.OuterBoxWithAnim.SpawnPropAt(SpawnTransform)
#             Sleep(0.2)
#             Assets.OuterBox.Dispose()
#         Assets.CollisionBarrier.Dispose()
#         Assets.Platform.TriggerLifetimeStartEvent.Signal()

#     # Teleport the MaybeExplosive
#     TeleportExplosive(SpawnTransform : transform):void =
#         if:
#             Explosive := MaybeExplosive?
#             Explosive.TeleportTo[SpawnTransform]

#     # Clear area of builds using the MaybeExplosive
#     TriggerExplosive():void =
#         if:
#             AgentToSpawn := MaybeAgentToSpawn?
#             Explosive := MaybeExplosive?
#         then:
#             Explosive.Explode(AgentToSpawn)
#         # spawn { ResetExplosive() }

#     # Reset the MaybeExplosive
#     ResetExplosive()<suspends>:void =
#         Sleep(0.15)
#         if(Explosive := MaybeExplosive?):
#             Explosive.Reset()
#             ExplosiveRetiredEvent.Signal(Explosive)

#     # Attempt to Teleport the Player to the spawn.
#     TeleportPlayer(SpawnTransform : transform)<suspends>:void =
#         if:
#             AgentToSpawn := MaybeAgentToSpawn?
#         then:
#             loop:
#                 if:
#                     FortCharacter := AgentToSpawn.GetFortCharacter[]
#                     FortCharacter.IsActive[]
#                 then:
#                     RefTransform := ReferenceObject.GetTransform()
#                     FortCharTransform := FortCharacter.GetTransform()
#                     CharDistanceFromCenter := Distance(FortCharTransform.Translation, RefTransform.Translation)
#                     # OffsetVector := CharDistanceFromCenter <= 200.0 and RefTransform.Translation - FortCharTransform.Translation or vector3{}
#                     OffsetVector := RefTransform.Translation - FortCharTransform.Translation

#                     TPTransform := transform:
#                         Translation := CharDistanceFromCenter <= 200.0 and SpawnTransform.Translation - RefTransform.Rotation.UnrotateVector(OffsetVector) or SpawnTransform.Translation + vector3{Z := 64.0}
#                         Rotation := FortCharTransform.Rotation.UnrotateBy(RefTransform.Rotation)

#                     if(Teleporter := MaybeTeleporter?, Teleporter.TeleportTo[TPTransform]):
#                         sync:
#                             AgentTeleportedEvent.Signal(Teleporter.TeleportedEvent.Await(), option{Teleporter})
#                             block:
#                                 Sleep(-1.0)
#                                 Teleporter.Teleport(AgentToSpawn)
#                         Print("Teleported Player via Device")
#                     else if(FortCharacter.TeleportTo[TPTransform.Translation, TPTransform.Rotation]):
#                         if(Teleporter := MaybeTeleporter?):
#                             AgentTeleportedEvent.Signal(AgentToSpawn, option{Teleporter})
#                         else:
#                             AgentTeleportedEvent.Signal(AgentToSpawn, false)
#                         Print("Teleported Player via TeleportTo")
#                     else:
#                         FortCharacter.Damage(200.0)

#                     # FortCharacter.ReleaseFromStasis() # ! # FIXME: Remember
#                     break

#     # Is Valid
#     IsValid()<transacts><decides>:void =
#         Assets.Platform.IsValid[] or Assets.OuterBox.IsValid[] or Assets.CollisionBarrier.IsValid[]

#     # Dispose All
#     Dispose():void =
#         Assets.Platform.Dispose()
#         Assets.OuterBox.Dispose()
#         Assets.CollisionBarrier.Dispose()
#         Assets.VisualBarrier.Dispose()