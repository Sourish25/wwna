# We Were Not Alone

A 3D horror/sci-fi game built with Godot 4.x Engine.

## Project Structure

This project follows a component-driven architecture for gameplay systems and a clean directory structure separating assets from source code.

```text
/ (Project Root)
├── assets/                # Imported and raw media assets
│   ├── audio/             # Sound effects and music
│   │   ├── music/         # Background music tracks
│   │   └── sfx/           # Ambient/situational sound effects
│   ├── fonts/             # Font files (.ttf, .otf)
│   ├── materials/         # Godot materials (.tres)
│   ├── models/            # 3D meshes (GLTF, FBX, OBJ)
│   └── textures/          # Material textures (albedo, normal, roughness)
├── src/                   # Game source files
│   ├── autoload/          # Global autoload singletons (EventBus, GameManager)
│   ├── characters/        # Entity scenes & scripts
│   │   ├── enemy/         # Enemy behavior scripts & scenes
│   │   └── player/        # Player controller & assets
│   ├── components/        # Reusable systems (Health, Hitbox, Hurtbox)
│   ├── levels/            # Level scenes & scripts
│   ├── ui/                # HUD, menus, interactive screens
│   └── utils/             # Math utilities, general helpers
├── .gitignore             # Git ignore file optimized for Godot 4
└── project.godot          # Godot project settings file
```

## Getting Started

1. Download and install [Godot Engine 4](https://godotengine.org/).
2. Open the Godot Project Manager, select **Import**, and choose `project.godot` inside this directory.
3. Once loaded, you can open and run level scenes located under `src/levels/`.

## Architecture Overview

### Autoloads
- **EventBus** (`src/autoload/event_bus.gd`): Global signal manager for decoupled game mechanics. E.g. connect player death directly to UI screen or level reset without child-to-parent coupling.
- **GameManager** (`src/autoload/game_manager.gd`): Maintains global state (PLAYING, PAUSED, GAME_OVER, MENU).

### Components
- **HealthComponent** (`src/components/health_component.gd`): Encapsulates health points, healing, and damage detection.
- **HitboxComponent** (`src/components/hitbox_component.gd`): 3D area representing a damage source (deals `damage` to hurtboxes).
- **HurtboxComponent** (`src/components/hurtbox_component.gd`): 3D area representing a vulnerable zone (receives `damage` and applies it to a sibling `HealthComponent`).
