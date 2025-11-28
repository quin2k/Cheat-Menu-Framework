# Quin2k's Cheat Framework Rework

![preview](ModScripts/_Mods/CheatFramework/preview.png)

[Latest version](../../releases/latest)

## Requirements

Lowest game version tested: `0.10.0.2`<br>
Highest game version tested: `0.10.3.1`

## Hotkeys
These should populate in the config when you load the mod for the first time.  If you want to disable any of these, set it to NONE instead of an F-key.  

<details>
<summary>Default Hotkeys</summary>

- MENU.Main Menu = F9
- MISC.Heal = F8
- MISC.Heal Wound = F7
- MISC.Money Now = F6
- TOGGLES.Infinite Health = F5
- TOGGLES.Infinite Stamina = F5
- TOGGLES.Infinite Food = F5
- TOGGLES.Auto Bandage = F4
- TOGGLES.Auto Clean Outside = F4
- TOGGLES.Auto Clean Inside = F4
- TOGGLES.Auto Cure = F4
- NONE.Remove Clothes = F3
- MISC.Force Remove Clothes = Shift+F3

</details>

## Known Issues

- Currently in need of proper translation for default languages. I didn't want to publish something I couldn't test, so I did not include custom languages from the original.
  - Any native speakers should contact me ASAP with fixes!

## Planned Improvements

- Fix & include summon options.
- Create a Config Menu interface with the following features:
  - Options to edit hotkeys in-game.
  - Consider handling other keys (M for example)
  - Options to edit menu order (for select menus).
  - Reset all settings to default (wipe select INIs)
  - Ability to toggle loading of mods and load order
    - (Don't expect load order to be a priority if menu order can be customized.)
- Create detailed documentation for registration system.
- Possible modification ideas:
  - Ability to set select (or all) global variables to act as local variables (save specific vs. game specific).  Not sure this is feasable, but seemed like a useful feature.
  - Ability to view all current global settings?


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

---

## Credits

See the [credits file](ModScripts/_Mods/CheatFramework/docs/Credits.md) for details.

Note from Quin2k: I freely give permission to improve on and use any of my contributions to the code as long as you respect / retain the credits of the original authors.  That includes previous authors taking up the project again.
