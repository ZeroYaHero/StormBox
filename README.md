# Storm Box
<img src="Supplements/T_SB_LogoOutline.png" alt="logo" width="512">

![Tools Used](https://skillicons.dev/icons?i=unreal,blender,python,photoshop,illustrator&theme=light)
<img src="Supplements/T_Verse.jpeg" alt="verse" width=50>
<img src="Supplements/T_SubstanceDesigner.png" alt="verse" width=50>
<img src="Supplements/SVG_Painter.svg" alt="verse" width=50>


### Table of Contents
- [Introduction](#introduction)
- [Storm](#storm)
    - [Logic](#logic)
    - [Material](#material)
    - [Post Process](#post-process)
- [Terrain Generation](#terrain-generation)
    - [Logic](#logic-1)
    - [Islands](#islands)
    - [Procedural Landscape Materials](#procedural-landscape-materials)
    - [Foliage Generation](#foliage-generation)
- [Spawn Generation](#spawn-generation)
    - [Logic](#logic-2)
    - [Cardboard Box](#cardboard-box)
    - [Platform](#platform)
- [UI](#ui)
- [Lobby](#lobby)
    - [Greybox](#greybox)
    - [Materials & Assets](#materials--assets)
- [Key Art & Rendering](#key-art--rendering)
- [Logo](#logo)
- [Videos](#videos)

## Introduction

<img src="Supplements/T_Storm_Fly.gif" alt="logo" width="384">

> **Figure 1**. Flying around the Storm Box as it moves through procedurally generated terrain.


Storm Box is a gamemode created by ZeroYaHero (me) in Fortnite's User Generated Content (UGC) Ecosystem with Epic Game's Unreal Editor for Fortnite (UEFN) and it's respective (and eventually UE6's) scripting language, Verse. It was developed between late 2023 and early 2024. As of 2025 it no longer recieves updates.

### Background

After doing a study where I recreated the Epic Game's Storm Shader seen in their Fortnite Battle Royale mode without looking at their methods or files, I wondered how I could use it in a new way. The first thought I had was making the storm a different shape.

In Fortnite, there are two very popular UGC gamemodes, Zone Wars, and Box Fights.
- In Zone Wars, players skip the looting process of a Battle Royale game, and are packed tightly in a smaller zone to duke it out. 
- In Box Fights, players similarly skip the looting process, but are enclosed in a small box with no exits and no natural cover.

Both of the gamemodes are traditionally assumed to take advantage of default Fortnite gameplay mechanics (weapons, building, healing, etc). 

With these two gamemodes being popular, I thought I should make the storm a small box shape. Taking advantage of the strengths of Box Fights & Zone Wars. A comfortable mixture of familiarity and innovation. 

## Storm

Code: [Src\SBI_Objects\SBI_StormBoxStorm](Src\SBI_Objects\SBI_StormBoxStorm)

### Logic
Storms or Safe Zones in Battle Royales are traditionally circles which randomly select a point within (or outside) the circle with a new smaller radius. With a box shape this is a little less natural, and not to mention the ceilings and floors. Wanting to have verticality, I decided storm phases should move in just one axis at a time (X, Y, Z) with a positive or negative direction. I also decided against having the box shrink. 

The storm phase generation process follows this pattern:
1. The Storm randomly selects an axis to move in. The pool of axises the storm can select from is done by checking the boundaries of the world, and eliminating any axis where the storm cannot move in its defined minimum distance (vertical and horizontal axis has two different minimum and maximum distances due to it being harder to climb than run).
2. Once an axis has been selected, a random value is generated between the minimum and the maximum (where the maximum is clamped to world boundaries) to add to the Storm transform. 
3. Repeat.

> A more primitive version of Storm Box called "Storm Box PvP" released in early 2023 which featured a shrinking box. However, the Fortnite Ecosystem seemed to prefer infinite game loops which allowed join-in-progress (JIP), so shrinking was not included for this release.

> When I was developing, I had not taken any linear algebra course, so there are areas which could be improved in the storm phase location selection.

### Material

<img src="Supplements/T_Storm.png" alt="procenv" width="384">

> **Figure 2**. Screenshot showcasing my recreation of Fortnite's Storm Material

At the time of making this game There was no way to write to the minimap material seen on a players heads up display (HUD). To communicate the direction of the Storm Box, I chose to customize my Storm Material to show *green* in the direction the storm was headed, and *red* in the opposite. You can kind of see this in the gif in the [introduction](#introduction).

### Post Process

## Terrain Generation
<img src="Supplements/T_ProcEnv_Demo.gif" alt="procenv" width="512">

> **Figure 3**. Editted gif showcasing the terrain generation cutscene, and me in debug mode no-clipping through another permutation with debug primitives drawn showcasing bounding box volumes of terrain islands.

### Logic

### Islands

### Procedural Landscape Materials



### Foliage Generation

## Spawn Generation

### Cardboard Box
<img src="Supplements/T_Box_Lit.png" alt="logo" width="256">
<img src="Supplements/T_Box_Wire.png" alt="logo" width="256">

<img src="Supplements/T_Box_Burn.gif" alt="boxburn" width="256">

### Platform

### Logic

## Logo

#### V1:
<img src="Supplements/T_SB_Logo_V0.png" alt="logo" width="256">

The first version of the logo was done in procreate. It had an old-school-Fortnite look. Using their infamous burbank font variation.
It was good to get the idea out there, but it felt a little too child-like. Not to mention, this logo was already in a pixel format meaning I could not upscale, and I did not have a license to use the font. 

#### V2:
<img src="Supplements/T_SB_Logo_V1.png" alt="logo" width="256">

I was still getting familiar with Adobe Illustrator at the time. I think I was actually really impressed with this look. Looking back, this looks horrendous compared to the procreate version.

#### V3:
<img src="Supplements/T_SB_LogoOutline.png" alt="logo" width="256">

This is the final version that you see associated with this project today. I am really happy with how it turned out. The box originally did not have the glowing sparkles, but it adds the alluring effect that the previous versions had. The lightning goes diagonally across the cloud, which is a lot easier to read at small sizes, instead of the sporadic small bolts seen in the previous versions. The inclusion of gradients adds a subtle but nice touch as well. I also own a license to the font. Yippie!

## Key Art & Rendering

### Logo
Initially I wanted to have a physically based 3D rendered logo which contained volumetrics. Additionally, there was a desire for it to be animatable as well. This was my first time using volumetrics and geometry nodes for the lightning. I went through multiple iterations.

#### V1:
<img src="Supplements/T_BlenderLogo_V1_P2.png" alt="logo" width="256">
<img src="Supplements/T_BlenderLogo_V1_P3.png" alt="logo" width="256">
<img src="Supplements/T_BlenderLogo_V1_P1.png" alt="logo" width="256">
<img src="Supplements/T_BlenderLogo_V1_P4.png" alt="logo" width="256">

#### V2:
<img src="Supplements/T_BlenderLogo_V2_P1.png" alt="logo" width="256">
<img src="Supplements/T_BlenderLogo_V2_P2.png" alt="logo" width="256">

The noise of the viewport actually made the volumetrics look a lot better, when rendered the denoiser made the clouds look more like slime or soap bubbles. I didn't really want to go into photoshop to make it more readable, as well.

Ultimately, I decided to go with a flat logo, as the colors popped more and it is just easier to read ([see logo section](#logo)). I did use and animate the second version for a teaser with my own "sound design," seen in [this Twitter video](https://x.com/ZeroYaHero/status/1695507653219504340?s=20).

### Thumbnail

## UI

## Lobby
<img src="Supplements/T_Lobby_Lit.png" alt="logo" width="512">
<img src="Supplements/T_Lobby_Unlit.png" alt="logo" width="512">

### Greybox

### Materials & Assets

<img src="Supplements/T_DamascusWall.png" alt="logo" width="512">

<img src="Supplements/T_ItemSpawners.png" alt="logo" width="512">


## Videos

- [Social Media Gameplay Trailer](https://x.com/ZeroYaHero/status/1820093582071718187)
- [Social Media Terrain Generation Teaser](https://x.com/ZeroYaHero/status/1816518781092659348)
- [Social Media Spawn Generation System Teaser](https://x.com/ZeroYaHero/status/1819804952719442407)
- [Social Media Gameplay Clip](https://x.com/ZeroYaHero/status/1819813367873208420)

8/14/24
Storm Box is gamemode created in Fortnite's User Generated Content (UGC) Ecosystem with Epic Game's Unreal Editor for Fortnite (UEFN) and it's respective scripting language, Verse.

All code, models, textures, logos, etc is designed by @ZeroYaHero (me), anything not created by me is created by Epic Games and offered to creators to use as seen in their EULA and Rules:
https://www.fortnite.com/news/fortnite-island-creator-rules

Gameplay videos that showcase Storm Box:
- https://x.com/ZeroYaHero/status/1820093582071718187
- https://x.com/ZeroYaHero/status/1816518781092659348
- https://x.com/ZeroYaHero/status/1819804952719442407
- https://x.com/ZeroYaHero/status/1819813367873208420
  

Storm Box derives from gamemodes already popular with the general combat engaged playerbase.
- One half of Storm Box originates from a mode where players enjoy combat in an enclosed-small-indestructible box with materials to build (Box fights).

- The other half takes from Zone Wars, a gamemode that essentially focuses the Storm/Zone mechanic from traditional Battle Royales (BR) that are used to force players into combat engagement, but simply omits the "looting" period of a game.
Storm Box makes that enclosed-small-indestructible box function the same as the Storm/Zone mechanic seen in BR and Zone Wars. 

Given this new combination of rules for this gamemode there were *hurdles* that made it harder to play Storm Box as you would other combat centric gamemodes. Most notably using environment design parallel to what Epic Games uses for their core modes like BR was not the right fit. This resulted in me designing my own Procedural Content Generation system to generate an environment for Storm Box, which is what most of the codebase reflects. It mirrors Voxel World generation like Minecraft using Noise to determine "Terrain Piece" placement.

Much of Storm Box's execution is done with the ecosystem in mind. Everything designed is tailored to capture the attention of typical Fortnite players accustomed to playing an occassional UGC experience. For those reasons the design for certain things is done in a way to not startle the average player.

Storm Box can be played following the directions seen here:
https://www.fortnite.com/@zeroyahero/7521-0495-2926
