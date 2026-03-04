# Asset Pipeline — ZacksGalacticAdventure

## Current State

The game currently uses placeholder shapes (ColorRect nodes) for all visuals. This document describes the intended pipeline for when pixel art assets are created.

## Planned Workflow

```
Raw Drawings (paper/tablet)
    ↓
Master 2D Files (high-res, layered)
    ↓  [Aseprite / Pixelorama / Photoshop]
Pixel Art Source Files (.aseprite / .pxo)
    ↓  [Export]
Individual Sprites (.png, power-of-2 where possible)
    ↓  [Spritesheet packer or Godot AnimatedSprite2D]
Spritesheets (.png + .json metadata)
    ↓  [Import into Godot]
SpriteFrames / AtlasTexture resources in Godot
```

## Folder Structure

```
game/assets/
  sprites/
    player/
      player_ship.png          Single frame or spritesheet
      player_thrust.png        Thrust animation frames
    enemies/
      basic_enemy.png
    bullets/
      player_bullet.png
    effects/
      explosion.png            Spritesheet for explosion animation
    ui/
      title_logo.png
  audio/
    level1.mp3                 Background music (already present)
    laser.wav                  Laser SFX (already present)
  fonts/                       Pixel fonts (.ttf or .fnt)
```

## Pixel Art Conventions

- **Base resolution**: 960x540 (viewport size)
- **Sprite sizes** (suggested):
  - Player ship: 20x24 px (current placeholder size)
  - Enemy: 22x22 px
  - Bullet: 4x10 px
  - Explosion: 32x32 px per frame
- **Color palette**: TBD — recommend limiting to 16-32 colors for old-school feel
- **Texture filter**: Nearest neighbor (already configured in project.godot)
- **Format**: PNG with transparency

## Import Settings (Godot)

For pixel art, ensure these import settings:
- Filter: **Nearest** (not Linear)
- Compression: **Lossless** for sprites, **Vorbis** for music, **WAV** for short SFX
- Mipmaps: **Off** for 2D sprites

## Animation Guidelines

- Target frame rate: 8-12 fps for pixel animations (retro feel)
- Use Godot's AnimatedSprite2D or AnimationPlayer
- Keep frame counts low: 3-6 frames for simple animations

## Audio

| File       | Type    | Usage           | Format |
|-----------|---------|-----------------|--------|
| level1.mp3 | Music   | Gameplay BGM    | MP3    |
| laser.wav  | SFX     | Player shooting | WAV    |

Future audio assets should follow:
- Music: `.ogg` (Vorbis) preferred for Godot, `.mp3` also works
- SFX: `.wav` for short effects (< 5 seconds)
- Keep music files under 5 MB where possible

## Tools

- **Aseprite** (recommended): Pixel art editor with spritesheet export
- **Pixelorama**: Free/open-source Godot-based pixel art editor
- **TexturePacker**: Professional spritesheet packing (optional)
- **Audacity**: Audio editing for SFX
