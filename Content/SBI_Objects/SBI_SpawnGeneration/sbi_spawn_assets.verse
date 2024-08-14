using { /Verse.org/Simulation }

using { SBI_VerseUtility }

# SpawnableProps used for the floating spawner.
sbi_spawn_assets<public> := class<concrete>:

    # Platform, builds attach.
    @editable       Platform : spawnable_prop = spawnable_prop{}
    # Outer Box
    @editable       OuterBox : spawnable_prop = spawnable_prop{}
    # Animation Outerbox
    @editable       OuterBoxWithAnim : spawnable_prop = spawnable_prop{}
    # Visual Barrier
    @editable       VisualBarrier : spawnable_prop = spawnable_prop{}
    # Collision Barrier, collides with characters but is actually invisible.
    @editable       CollisionBarrier : spawnable_prop = spawnable_prop{}

    # Make an instance 
    Clone()<transacts>:sbi_spawn_assets =
        sbi_spawn_assets:
            Platform := Platform.Clone()
            OuterBox := OuterBox.Clone()
            OuterBoxWithAnim := OuterBoxWithAnim.Clone()
            CollisionBarrier := CollisionBarrier.Clone()
            VisualBarrier := VisualBarrier.Clone()
