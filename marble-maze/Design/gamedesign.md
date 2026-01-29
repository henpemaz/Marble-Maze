# <center>Game Template Thing
## <center>Game design document

<br>

**Notice**: this is a .md document. It can only be as fancy, don't waste your time trying to make it fancier. If you really need table of contents, numbered sections, footnotes etc, either move to LaTeX, googledocs, or rethink your priorities. Personally I'd just use something like **Obsidian** or online alternatives, non-linear documents are great for laying ideas down and sectorizing stuff, I'm doing a document instead since its a very very small scope thing.

The same sort of applies for this template. It's just a solid template of the BASICS, it doesn't try to be a "framework for any game". Don't make things that won't be used >80% of the time.

## Motivation

Building a game in Godot involves some repetitive tasks of setting up scene transitions, save managers, menu transitions, settings menu, multiple resolution support, save systems and so forth. Every time. For every game. If you know how to do and what to do, it's just repetitive tasks, but there's room for following good architecture patterns that are easy to expand on later.

## Scope

Game Template Thing is a very simple game designed with the goal to develop a template for games in Godot.

The gameplay is kept to a minimun, while focusing on systems that are commonly presents in games, such as menus, levels, cinematics, collectables, pause menu, to name a few. It comes with the bare minimun functionality, but that bare minimun is properly architected and can be expanded on as needed.

This template still needs a competent dev/programmer to learn and expand on. I'm setting up a good *fundamental architecture* for you, I'm not making code-free tools or anything like that.

## Flow

To help development, I suggest a **flow-first** approach, where each component of the game is mocked and implemented to a minimun to enable the flow from scene-to-scene through the expected path.

Upon boot, the game displays a **Splash-Screen** containing animation and logo. Once the splash-screen is done, the game goes to the **Main Menu** screen, where the player has options to:
- Play/continue
- Select a level to replay
- View found secrets/items
- Configure settings
- Exit the application

Selecting play/continue or a level brings the player to the **Play-area** ("Level"), where gameplay happens.

At the end of each level, a **Recap** screen is displayed, and the player is prompted to:
- Continue to the next level
- or Return the Main Menu

On the last level, instead, **Credits** roll, the recap is displayed, and the player's only prompt is to return to menus.

## Splash Screen

The splash screen plays an animation and audio which ends in the logo being displayed.

Once the logo has had a couple seconds of screentime, the scene switches to the main menu.

## Scene Transitions

All scene transitions are done through a singleton (global/autoload) that handles async loading. It also contains a rect used for fading out and in scenes. Fade is set to white, people using the template are encouraged to change it.

If a scene is not done loading once the fade-out of the previous scene is done, a loading screen is displayed. A loading screen can also be forced to display for a minimun set amount of time to show it off.

## Main Menu

The main menu presents a **main interface** with a **play** button ("continue"?), a **level-select** button, a **collection** button, a **settings** button, and an **exit** button.

the menu can be navigated with arrow-keys or WASD, and Enter or Z and Return(bkspc) or X or Esc. Trying to back out of the main interface shows a "Are you sure you want to exit?" confirmation.

The **play** button plays the first unfinished level available. If no levels are left to play, it prompts the player to "re-start the campaign".

For the scope of flow-first, newgame is the sole functionality of the main menu to be fleshed out first.

The **level-select** button brings the player to a second screen, where previews of each level form a grid the player can choose from. The player can back out of this secondary menu, or select a level and play.

If "**no levels are available**", then the button is hidden/disabled. By "no levels available", what's understood is that the player hasn't completed or started any levels.

The **collection** button brings a screen where collected items are shown as previews in a grid. Selecting/hovering an item brings up a description on the second half of the screen.

Items that have been collected show a preview and have a description, while items that haven't been found yet show as a "?".

The **settings** button brings the player to a second screen where settings can be tweaked. This menu displays the following categories and settings:

#### Graphics
- Fullscreen vs Windowed
- 3D render scale
- V-sync
- FPS Limit
- Antialiasing

#### Audio
- Master Volume
- Music Volume
- Dialogue/Cutscene Volume
- SFX Volume

#### Accessibility
- Allow skipping new cutscenes
- See credits button

Each setting (category??) has an option to restore it to default??

Aditionally, there's an option to restore all settings to default??

Settings are saved across sessions on a file that's separate from the "save" file, and are not reset when the save is reset.

The **exit** button closes the game.

## Game

The game consists of a play-area where the player can move around in 2d space. There's one item to collect in each area, one enemy that decreases the player health, and a "end-of-level teleporter" to the next area. Reaching the teleporter is refered to as "completing" an area.

When the player completes an area, the gameplay freezes and a "Recap" screen is displayed overlaying the game. The recap screen has UI navigation to continue to the next level, or go to the main menu.

If the player's health reaches zero instead, a gameover screen shows up, with options to retry the level or go to the main menu.

The player can pause at any time during the game, except when the Recap screen is displayed. The Pause Menu is described in the next section.

The first area has a white background. The player starts on the left, the teleporter is on the right. North there's a twig item that can be collected.

The second area has a green background. The player starts on the top, the teleporter is on the bottom. West there's a leaf item that can be collected.

The third area has a red background. The player starts on the bottom-left, and the teleporter is on the top-right. There's a rock item that can be collected.

Completing the third area (reaching the teleporter) goes to the credits scene. The recap is displayed at the end of the credits. "Skipping" the credits brings the player to the recap.

## The Pause Menu

The pause menu can be brought up "during gameplay" by pressing escape. Gameplay is frozen while the menu is up. The menu has the following options:

- Resume
- Restart Level
- Settings
- To Main Menu

The settings button navigates to a submenu where settings can be tweaked similar to the main menu one.

## Recap screen

This is a screen that is displayed overlaying the game or credits scene. If there were any meaningful statistics we could display them here.

The player has an interface to either continue to the next level, or return to menus. After credits, theres only the option to return to the main menu.

## Credits scene

The credits scene shows credits. They scroll bottom-to-top (as in camera moves top-down).
This is a "cutscene" that can be skipped if the player has already seen it before.
