# Quin2k's Cheat Framework Rework

![preview](ModScripts/_Mods/CheatFramework/preview.png)

[Latest version](../../releases/latest)

## Install Instructions
 - Put the CheatFramework folder into LonaRPG\ModScripts\_Mods. (e.g. LonaRPG\ModScripts\_Mods\CheatFramework\__init__.rb)
 - Once in place, open the MODS menu from within LonaRPG (right above EXIT).
 - Press action key (Z) to activate mods, left/right to change their order. 
   - The one that loads last 'wins'
 - When using a new mod or bringing mods to a new version of LonaRPG, it is good practice to activate only a few at a time.
 - Once you've made your changes, move to the top and select "Restart to Apply" (or Accept and just restart manually)
   - If you get an error during startup, you may need to edit LonaRPG\UserData\GameMods.ini to deactivate a mod.
   - If CheatFramework is giving you errors, delete/edit LonaRPG\UserData\Cheat Framework\globals.ini
   - If any of my mods give you errors, please notify me on [F95zone](https://f95zone.to/members/quin2k.428612/) or [Discord](https://discord.com/users/292323791533506560).

## Requirements

Lowest game version tested: `0.10.0.2`<br>
Highest game version tested: `0.10.7.5.16`

## Hotkeys
These should populate in the config when you load the mod for the first time.  If you want to disable any of these, go to Config > View/Clear Hotkeys.  Any command or toggle can be assigned a hotkey by pressing **C** to edit, a key or combo, then  **C** again to save. 

Key combos can include Shift/Ctrl/Alt. Usable keys are any unused F-key, letter (T, Y, U, I, O, P, G, H, J, K, L, V, B, N, M), digit (1, 2, 3, 4, 5, 6, 7, 8, 9, 0), or symbol `; = , - . / [ \ ] '` that is not otherwise assigned in a known Mod or the Keyboard Key Bindings Menu. If there is a conflict, the shortcut key will not update. .

The Cheat Menu still defaults to **F9**. You can change this in the hotkeys.ini, the Key Bindings Menu or in Config > View/Clear Hotkeys in the cheat menu. Can't get into the cheat menu? It is also mapped to the Settings Menu (the save/load screen).

<details>
<summary>Default Hotkeys</summary>

- MENU.Main Menu = F9
- NONE.Remove Clothes = F3
- MISC.Force Remove Clothes = Shift+F3
- MISC.Bank Anywhere = F2
- TOGGLES.Infinite Health = F4
- TOGGLES.Infinite Stamina = F4
- TOGGLES.Infinite Food = F4
- ROLEPLAY.Infinite Mana = F4 (RolePlay-S mod only)

Conflict Resolution: If the RolePlay-S mod is active, quick-save/load will override any hotkeys assigned to F5/F6. Similarly, if you reassign Cheat Menu's hotkey, any overlapping hotkeys will be unbound.

</details>

<details>
<summary>Menu Structure</summary>

- Misc. Cheats
  - Heal
  - Heal a Wound
  - Exhausted
  - Give Money
  - Force Unequip
  - Summon NPC Submenu
    - Auto-populated
  - Edit World Difficulty
  - Revive Unique NPCs Submenu
  - Deepone Summon Max
  - Open Bank Inventory
  - Reset Game Difficulty (Doom Mode only)
- Toggles
  - Infinite Health/Stamina/Food/Money
  - Unlock Gallery
  - Disable Dirt
  - Auto-Bandage
  - Auto-Clean
  - Auto-Cure
- Character
  - Primary
    - Health Edit
    - Stamina/Food Edits
    - Mood Edit
    - Dirt Edit
    - Arousal/Morality Edits
  - Levels
    - Max Levels
    - Current Level
    - Traits per Level
    - Set current Trait Points (duplicate)
  - Traits
    - Set Max Traits
    - Set current Trait Points (duplicate)
    - Edit Combat/Scoutcraft/Wisdom/Survival/Constitution
    - Reset Traits (points allocated to skills, etc.)
  - Race
    - Set Lona's Race
    - Enable Racial Skills (Abomination/Deepone)
  - Pregnancy
    - Preg Difficulty / Womb Seedbed (Impacts pregnancy length)
    - Protect Pregnancy (Infinite Baby Health)
    - Impregnate Lona (Submenu, force specific race)
  - Appearance
    - Hair Color
    - Freckles
    - Pubic Hair
  - Sexual
    - Vaginal/Urethra/Anal Damage Edit
    - Vaginal/Urethra/Anal Damage Toggle
    - Reset Sex Stats (Virginize)
- Game Tweaks
  - Item Decay Control
  - Increased Drops
  - Equip Anything
  - Friendly Fire Fix
  - From The Shadows Fix
  - Abomination Eat Fix
  - Difficulty Achievement Fix
  - Prevent Discard
- Items/Weapons/Armors/Status
  - Auto-populated 
- RolePlay-S
  - Edit Mana Rage Max
  - Disable Save Limiter
  - Infinite MP
  - Edit Mana Rage
- Config
  - View/Clear Hotkeys
  - Edit Menu Order 
  - Edit Globals 
  - Reset Config Settings

</details>


## Known Issues

- Currently in need of proper translation for default languages. I didn't want to publish something I couldn't test, so I did not include custom languages from the original.
  - Any native speakers should contact me ASAP with fixes!
- Giving birth while Infinite Stamina is active causes issues (Lona is supposed to faint, but doesn't).

## Planned Improvements

- Possible modification ideas:
  - A code review pass over the existing modules/cheats to double check everything still works as intended.
  - More cheats: 
    - Night Vision (inspired by RolePlayS), 
    - SeaWitch Fix (inspired by Lona Can Communicate)
    - Fast Sleeping (existing mod I always add)
    - Hire Companion from Anywhere (better than random summon)
  - Cache the Items/Weapons/Armor/Status editor lists instead of rebuilding them from scratch every time
    the menu opens.
  - Mod integration: expose config options in the cheat menu for LonaBellyBooba and FilterVisuals.
  - Fix Trait Point calculation adding a decimal (`.0`) to the trait variable.
  - Tweak Freckles so it's a list (Off/On tied to 0/1) instead of an edit_num.

---

## Changelog

<details>
<summary>Ver 0.9.0q Changelog</summary>

This started out as "I'd like to be able to edit variables" and when I realized the last editor for the Cheat Mod didn't seem active anymore, I decided to try my hand at it.  Since then, I've done the following:

- Completely refactored Init, Config, Menu. Added library resources to Utils file to simplify loading. 
- Created a 'default' UI that can handle commands, toggles, editing numbers and lists, and even nested menus.
- Added the ability to dynamically created menus and structures for the menu without preventing the old format.
- Also added a way to register hotkeys as part of the command creation process.
- Set up default sections for toggles and miscellaneous commands.
- Added ways to simplify and streamline command creation/mapping so that a few tags can create most commands.
- Incorporated dynamic hotkey generation into the command mapping system.
- Developed a variables interface to directly edit various stats for Lona (Health, Stamina, Food, Mood, Arousal, Levels, Traits, etc.)
- Incorporated Morality and Hair Color into the menu.  Added World Difficulty for good measure.
- Drew inspiration from code on the Wiki (Author Unknown) for Max Level Increase, Max Stat Increase, and Traits per Level mods.
- Added recalculation functions for traits and a way to rest all traits easily (effectively reroll your character).
- Revamped Pregnancy module:
  - Improved code for pregnancy duration edit.
  - Added a way to edit baby health and lock it to max.
  - Added special difficulty setter that would only influence pregnancy (for longer/shorter lengths)
  - Put a convenient Womb Seedbed setter in the page and improved UI.
- Created a sub-menu called Character to house Levels, Traits, Primary, Pregnancy, Appearance and Race editors.
- Added toggling of Race Skills to Race Edit menu (can of course also unlock them legitimately!)
- Imported Stat (I'm calling it Status), Item, Weapon, and Armor editors.
- Developed a CG Unlock Toggle that doesn't edit achievements (watching the scenes could possibly add them).
- Merged Infinite Stats, Infinite Money and Dirt toggles along with legacy commands that aren't redundant from changes above.
  - Tried to incorporate features to reduce lag issues mentioned in previous version.
- Updated Auto-Bandage and Auto-Clean splitting it for internal (cum tanks) and external and added a new Auto-Cure (STDs, parasites).
- Implemented unequip and force unequip hotkeys, also adding Force Unequip as a menu item just in case.
- Added the various 'fixes' and made them toggleable - this should allow users to disable ones that are causing crashes.
  - NOTE: ALL OF THESE TOGGLES REQUIRE RESTART BEFORE THEY WILL ENABLE/DISABLE.
  - Fixed issues with StripOnlyUnequips (now "Prevent Discard")
  - Imported Abomination Desicrate skill fix which makes eating corpses heal wounds and sate hunger.
  - Included toggleable fixes for difficulty-based achievements and a fix to "Into the Darkness" stealth.
  - Improved on the Friendly Fire code to completely prevent damage/aggro between player and followers.

</details>
<details>
<summary>Ver 0.9.1q Changelog</summary>

- Minor change to config file structure before initial release (split global/hotkeys/modules to separate ini files fixed quotes being added to hotkeys.) 

</details>
<details>
<summary>Ver 0.9.2q Changelog</summary>

- Fixed some issues with Friendly Fire Fix not recognizing summons (e.g. Cocona undead) as allies.
- Fixed issue where editing pregnancy wasn't updating Lona's belly until the next day.
- Found and fixed an issue with Traits Per Level global not loading properly. If you have issues, delete that line or capitalize "Per"
- Determined the low-lag features were voiding the whole point of max hp/sat/sta (wasn't preventing death!!) so sped up the check frequency.
- Main menu is now prioritized over other commands and doesn't check for Ctrl/Shift/Alt. Keep that in mind if customizing hot keys.
- Moved the "fixes" to their own menu named "Game Tweaks"
  - Moved Prevent Discard to that section.
- Added some features inspired by doujinftw in F95zone
  - Option to edit mob drop quantity.
  - Option to adjust/remove dropped item decay.
  - Option to disable equipment restrictions (MagicEQ, HighQuEQ, SaintEQ) no matter what traits you have.
    - I wanted to do "learn any skill" but this is more future-proof.
- Added a menu in the Game Tweaks to revive unique NPCs. Inspired by one of kastrom's mods on raidgame.ru.
- Included some rebirth traits in "Appearance" menu including freckles, pubic/anal hair, and pube growth rates (if active).
- Tried to improve language support. If you would like to contribute, go to [Google Docs Translation](https://docs.google.com/spreadsheets/d/1hoDT0cJfvXVhomTkJyq5G6tgjrkiBAm26lsjEOWU3_k/edit?usp=sharing).
  - Russian updated courtesy of Sadorimatsu at F95zone.to / raidgame.ru
  - If you aren't comfortable accessing via Google Docs, DM me and I'll send an excel version.

</details>
<details>
<summary>Ver 0.9.3q Changelog</summary>

- Fixed a typo in Protect Pregnancy code that prevented Baby Health updates.
- Added a command to access the bank from anywhere. For those who have hoarding issues.
  - Set it to F2 as a shortcut.
- Finally ported over Summon interface from the original mod.  Merged some sections.
  - It should work exactly the same, BUGS AND ALL, so use with caution!
- Moved Revive, Summon, World Difficulty, and Bank to new "NPC" Submenu.
  - Revive menu will now display non-dead NPCs as grayed out (so the menu isn't blank)
- Added a "Sexual" menu under "Character" 
  - Adds number editing and toggles for Vag/Urethra/Anal Damage 
  - Has a command to reset all sex stats - essentially restoring virginity.
- Added option to "Reset Game Difficulty" to the Misc Cheats Menu.
  - Basically force-disables Doom Mode. Only visible in Doom Mode.
  - **Use with caution, can delete your Doom Save.** When testing, entering the game menu before running the cheat seemed to preserve it - but no promises.

</details>
<details>
<summary>Ver 0.9.4q Changelog</summary>

- RolePlay-S Compatability update!
- Disabled cheats for Max Level (redundant) and Traits Per Level (conflict) if RolePlay-S mod enabled.
- Disabled font overrides for cheat menu. Could still force it by removing the default font.
- Added a new RolePlay-S Menu for mod-specific cheats:
  - Unlimited Saves: Cheat will prevent counting saves, and will reset save count upon load (for games saved before cheat enabled).
  - Infinite MP: Functions similar to infinite HP/Sta/etc.
    - Tied to F5 toggle too.
  - Mana Rage & Mana Rage Max: Allows you to edit variables. 
    - Rage increases 1:1 for every MP used and if maxed you die.
    - Probably only necessary to edit with Infinite MP active.
- Moved Friendly Fire to NPC Category
- Added a cheat to edit max summonable Sirens for Deepone to NPC Category.
- Changed UKR to MTL from Russian instead of English. Figured it'd be more accurate.

</details>
<details>
<summary>Ver 0.9.5q Changelog</summary>

- Minor corrections to fonts (missed some menus impacted by the RolePlayS mod).
- Code fix for Friendly Fire courtesy of Archangel Dejavu at RaidGame.ru
- Identified and hopefully fixed file loading issues for some non-english characters.
  - Started utilizing mod loader to read files vs. attempting to do it directly.

</details>
<details>
<summary>Ver 1.0q Changelog</summary>

- Added a in-menu way to access the Cheat Menu (same page as Load/Save).
- Added a way to set/clear hotkeys directly (Only works w/ Commands and Toggles)
- Added the ability to set hotkeys in-game with C, (key), C.
  - Includes conflict resolution, preventing/clearing hotkeys that conflict.
- Implemented Config Menu with the following features:
  - View Hotkeys 
    - Ability to edit Cheat Menu hotkey in-game (F2, F3, F4, F7, F8, F9, F11)
    - Ability to view/clear existing hotkey bindings.
  - Edit Menu Order
    - Ability to customize all menus (including the config menu, globals menu).
  - Edit Globals
    - Ability to force some local variables to act as global variables (across saves)
    - Ability to force select global variables to act as local variables 
      - (let me know if I should add more).
    - Ability to set these variables in a centralized area.
  - Reset Config Settings
    - Returns config settings (order, hotkeys, etc.) back to default.

</details>
<details>
<summary>Ver 1.1q Changelog</summary>

- Moved ini files to mod folder (heard that has less conflicts for JoiPlay).
  - (Good time, since a lot has been changed)
- Moved some menu items around.
- Added an 'alert' to inform if a cheat may not be working until restart.
- Fixed "Force Remove" cheat to not remove hair (still removes chains/bondage).
- Fixed long load times for Items/Armors/Weapons/States menus.
- Merged Auto-Clean (Internal/External) into a single Auto-Clean toggle - the split never worked right, since cum states are just a display derived from the cum tanks, so clearing one without the other just got undone on the next h-event.

</details>
---

## Credits

See the [credits file](ModScripts/_Mods/CheatFramework/docs/Credits.md) for details.

Note from Quin2k: I freely give permission to improve on and use any of my contributions to the code as long as you respect / retain the credits of the original authors.  That includes previous authors taking up the project again.
