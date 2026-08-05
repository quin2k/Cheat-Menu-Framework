# Cheat Framework: Module Guide

This explains how to add a cheat to the Cheat Framework, written for someone who isn't necessarily
comfortable with Ruby or programming yet. It focuses on "what do I write, and what does it do" rather
than how the framework is built internally.

The best example file to read alongside this guide is
[`modules/Pregnancy.rb`](../modules/Pregnancy.rb) — nearly everything below shows up somewhere in it.

A few words you'll see a lot:

- **Module** — one `.rb` file, containing one or more related cheats.
- **`$something`** — a "global variable." Any file can read or change it. Most cheats store their
  on/off state or number in one of these.
- **Symbol** (`:toggle`, `:my_key`) — just a label Ruby uses internally. You don't need to understand
  why it's written that way, just copy the pattern shown in examples.
- **Monkey-patch** — changing how an existing piece of the game behaves, instead of adding something
  new. Covered in §7.

---

## 1. How a module gets loaded

Drop a `.rb` file anywhere under `modules/`. The framework finds it automatically at startup — you
never have to register the file itself anywhere. It reads a small header at the top of your file (see
§2), then runs your file's code once, top to bottom, like any Ruby script.

## 2. Your module's header (optional, but recommended)

```ruby
FrameworkModule = {
  name:       "Pregnancy",   # Just a label, shown in a couple of places
  key:        :pregnancy,    # A short, unique name for your module (no spaces)
  menu:       :PREGNANCY,    # Which menu group your commands land in by default
  depends_on: [],            # Other modules' :key values that must load before yours (usually empty)
}
```

If you skip this, the framework guesses reasonable defaults from your filename. Fine for a very small
file that only patches existing game behavior and doesn't add its own menu entries.

## 3. Adding a cheat to the menu

Every cheat — a toggle, an editable number, a button — is one `register_command` call:

```ruby
module MenuFramework
  module SUBMENU
    register_command(
      group:  :PREGNANCY,
      type:   :toggle,
      key:    "Protect Pregnancy",
      label:  "modules/pregnancy:commands/protect",
      state:  "$cheat_protect_pregnancy",
      gdef:   false,
    )
  end
end
```

- **`group:`** — which existing menu screen this shows up in (`:MISC`, `:TOGGLES`, `:LONA` are common
  ones already used elsewhere — reuse one rather than inventing your own unless you're building a
  whole new screen, see §4).
- **`type:`** — what kind of row this is. See the table below.
- **`key:`** — a name for this specific command. Must be unique within its `group:`.
- **`label:`** — the text shown to the player. This is a *text key*, not the literal words — see §9.
- **`state:`** — a piece of Ruby, written as **text** (in quotes), that reads the cheat's current value.
  Almost always just a `$variable` name.
- **`gdef:`** — the default value, and a signal to the framework "please remember this setting between
  play sessions for me." See §5.

## 4. Command types (`type:`)

| type | What it is | You must also provide | Example use |
|---|---|---|---|
| `:toggle` | A simple on/off switch | `state:` | "Infinite Health" |
| `:edit_num` | A number the player can raise/lower | `state:`, `min:`, `max:` | "Max Level" |
| `:edit_list` | Cycles through a fixed set of choices | `state:`, `list:` | "Drop Rate: x1/x2/x4" |
| `:action` | A button that just runs some code once | `action:` | "Heal Fully" |
| `:info` | Read-only text, nothing to press | `state:` | Shows a calculated value |
| `:scene` | Opens a whole new screen | `name:`, `dict:` | See §4a |

### `:toggle` example

```ruby
register_command(
  group:  :PREGNANCY,
  type:   :toggle,
  key:    "Protect Pregnancy",
  label:  "modules/pregnancy:commands/protect",
  state:  "$cheat_protect_pregnancy",
  gdef:   false,
)
```

### `:edit_num` example

```ruby
register_command(
  group:  :PREGNANCY,
  type:   :edit_num,
  key:    "Seedbed",
  label:  "modules/pregnancy:commands/seedbed",
  state:  "$game_player.actor.stat['WombSeedBed']",
  min:    0,
  max:    10,
  action: ->(v) { FrameworkUtils.custom_state_edit("WombSeedBed", v) },
)
```

Left/Right in-game raises or lowers the number. `action:` here is a small piece of code that actually
applies the new value `v` to the game — needed because this cheat edits something that's already part
of the save file, not a setting the framework can just remember for you (more on that distinction in §5).

### `:edit_list` example

```ruby
register_command(
  group:  :PREGNANCY,
  type:   :edit_list,
  key:    "Pregnancy Difficulty",
  label:  "modules/pregnancy:commands/difficulty",
  state:  "$cheat_pregnancy_difficulty",
  gdef:   -1,
  list:   [
            { key: -1, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
            { key:  0, label: "[#{$framework.txt("menu:commands/diff_hard")}]" },
            { key:  1, label: "[#{$framework.txt("menu:commands/diff_hell")}]" },
          ],
)
```

Each entry in `list:` is one choice: `key:` is the actual value stored, `label:` is what's displayed.
Unlike the top-level `label:`, each list entry's `label:` must already be the *finished, translated
text* — call `$framework.txt(...)` yourself, as shown, rather than passing a bare text key.

### `:action` example

```ruby
register_command(
  group:  :IMPREGNATE,
  type:   :action,
  key:    "Clear",
  label:  "modules/pregnancy:commands/clear",
  action: -> { $game_player.actor.cleanup_after_birth },
)
```

Pressing this just runs the code in `action:` once. Nothing to remember, nothing to persist.

### `:info` example

```ruby
register_command(
  group:  :PREGNANCY,
  type:   :info,
  key:    "BabyRace",
  label:  "modules/pregnancy:info/babyRace",
  state:  "$game_player.actor.baby_race",
  hide:   -> { $game_player.actor.preg_level == 0 },
)
```

Just displays whatever `state:` currently is. `hide:` (see §6) is often paired with `:info` rows to
only show them when they're relevant.

## 4a. Adding a whole new screen

If your cheat needs its own dedicated page (like Pregnancy's own menu), register one `:scene` command
that opens into a new group, then register your real commands *into* that group:

```ruby
register_command(
  group:  :LONA,                 # the screen this link itself appears on
  type:   :scene,
  key:    :pregnancy,
  label:  "modules/pregnancy:commands/preg",
  name:   "CheatMenuPregnancy",  # the framework builds a screen named after this automatically
  dict:   :PREGNANCY,            # your new group - use this as group: on the commands that belong here
)
```

You don't need to build the screen by hand — the framework generates it the first time it sees that
`name:`. That's enough for the vast majority of cheats. Building a fully custom, hand-drawn screen is
possible but a much bigger topic — look at `Controls.rb` or `InvEdit.rb` for examples if you need it,
or ask someone familiar with the framework for help.

## 4b. Adding your own row to the *Main Menu* (root screen)

§4a's `group:` puts your new screen's link *inside* an existing category, like `:LONA`. If instead you
want your module to show up as its own row on the root screen — the one the player sees when pressing
the Main Menu key, alongside "Miscellaneous," "Toggles," "Character," and "NPC Options" — register with
`MenuFramework::MENU` instead of `MenuFramework::SUBMENU`:

```ruby
module MenuFramework
  module MENU
    register_command(
      type:  :scene,
      label: "modules/mymodule:commands/root",
      name:  "CheatMenuMyModule",
      order: 40,
    )
  end
end
```

If your `FrameworkModule` header (§2) already sets `menu:`, that value becomes this new screen's group
automatically — you don't need to pass `dict:` yourself, and any `MenuFramework::SUBMENU.register_command`
calls in the same file don't need `group:` either, for the same reason. `modules/Fixes.rb` is a small,
complete example of this: one `MENU` entry ("Game Fixes") holding several plain `SUBMENU` toggles, none of
which mention `group:` because the header's `menu: :FIXES` already ties them together.

Everything else about the `:scene` command (`type:`, `label:`, `name:`) works exactly like §4a. The only
difference is *where* the link to your new screen appears: `MENU` puts it on the root screen, `SUBMENU`
(with a `group:`) tucks it inside whichever existing category you choose instead.

## 5. Making your cheat remember its setting (`gdef:` + `state:`)

Pass both `gdef:` (a default value) and a `state:` that's a plain `"$variable"` name, and the framework
handles saving/loading for you automatically:

- When the game starts, it reads your cheat's last saved value (or uses your `gdef:` default the very
  first time) and puts it into the variable.
- When the player changes it, the framework saves the new value for next time — you don't need to
  write any extra code for this, as long as you didn't supply your own `action:`.

**When *not* to use `gdef:`:** if your cheat edits something that's already part of the save file
itself — health, level, an NPC's story flag — don't use `gdef:` at all. That kind of value is already
being saved by the normal game, and needs its own `action:` that actually changes the game object
(see the `:edit_num` example above). `gdef:` is only for a cheat's *own settings*, not for game data
that already exists.

## 6. Showing, hiding, and coloring rows

- **`hide:`** (`true`/`false`, or `-> { }` for a live check) — removes the row from the list entirely.
  Use this when a row makes no sense right now (a pregnancy-only field while not pregnant).
- **`enable:`** (default `true`) — keeps the row visible, but grays it out and marks it "Cheat Active"
  when `false`. Use this for "this is temporarily blocked by another setting," rather than hiding it.
- **`color:`** — a number that picks a text color, or a `-> { }` that returns one. `16` is commonly
  used to highlight "this is the currently active choice"; `8` for a dimmed/informational row.

## 7. Changing how the game itself behaves

Everything so far adds a *new* row to a menu. Sometimes you want to change something the game
*already* does — for example, "block friendly fire" or "let True Deepone talk to NPCs normally."
That's done by replacing one of the game's own methods with your own version, a technique usually
called **monkey-patching**.

The key trick: keep a copy of the original under a new name first, so you can still fall back to it:

```ruby
if $cheat_my_fix >= 0                    # only bother at all if the cheat isn't fully disabled
  class Game_Actor                        # reopen whatever class already defines the thing you want to change
    alias_method :my_fix_original_heal, :heal_wound  # keep a working copy of the original, under a new name

    def heal_wound                        # replace it with your own version
      return my_fix_original_heal unless $cheat_my_fix == 1   # only actually change anything if the toggle is on
      # ... do your own thing here ...
    end
  end
end
```

A few things worth understanding line by line:

- `class Game_Actor` doesn't create a new class — since `Game_Actor` already exists in the game, this
  *reopens* it, letting you add or replace methods on it. This works for any class in the game.
- `alias_method :new_name, :old_name` copies the method currently called `old_name` and gives that copy
  a second name (`new_name`). After this line, both names point at the *same, original* behavior.
- The `def heal_wound` right after it then replaces `heal_wound` with your version. Since you already
  saved a copy under a different name, you can still call the original whenever you want (as shown:
  falling back to it when the cheat is off).
- Wrapping the whole thing in `if $cheat_my_fix >= 0` means: don't even attempt any of this unless the
  cheat has been turned on. If your cheat has ever been fully "Disabled," none of this code runs at
  all — which matters if the game ever updates and changes how `heal_wound` works, since your patch
  never touching it at all is the safest possible outcome.
- Checking `$cheat_my_fix == 1` *inside* the replaced method (rather than only in the outer `if`) is
  what lets the player flip the cheat on and off during play without restarting — see §8.

Always alias to a name that's unique to your cheat (like `my_fix_original_heal`, not just `original`)
so two different modules changing the same method don't collide with each other.

**If you're only adding something new** (a brand-new method the game doesn't already have), you don't
need `alias_method` at all — there's nothing to fall back to. Just reopen the class and write your
method directly, the same way §7's `class Game_Actor` line reopens one.

### 7a. Running code every tick

Some cheats aren't triggered by the player pressing anything — they need to check something
continuously (an aura effect, a passive drain). Reopen `CheatFramework` itself and alias its
`hotkey_trigger` method, which the framework already calls once per frame:

```ruby
class CheatFramework
  alias_method :my_fix_hotkey_trigger, :hotkey_trigger

  def hotkey_trigger
    my_fix_hotkey_trigger
    # ... your own per-tick check here ...
  end
end
```

Same pattern as §7 — keep a copy of the original under a new name, then call it alongside your own
code, so every other module's tick logic keeps running too.

### 7b. Checking if another mod is enabled

If your patch would conflict with a specific other mod, gate it out when that mod is enabled:

```ruby
if $mod_manager.mods['SomeOtherMod'] && !$mod_manager.mods['SomeOtherMod'].enabled
  # ... your patch here ...
end
```

Pair this with `hide: -> { $framework.some_other_mod_enabled? }` (or an equivalent check) on the
`register_command` itself, so the row disappears entirely rather than sitting there doing nothing.

## 8. Restart behavior (`restart:`)

Some cheats can only take effect the moment the game starts (the monkey-patching in §7 can only run
once, when your file first loads) — so if a player turns one on for the first time, nothing will
actually happen until they restart. Left unmarked, that's confusing: the player sees their setting
saved as "On" but nothing changed.

If your cheat has this restart requirement, add `restart:` with the number your `list:` uses to mean
"fully off/disabled" (commonly `-1` or `0` — whatever you picked). For a plain `:toggle` with no such
number, use `restart: true` instead.

```ruby
register_command(
  ...
  state:   "$cheat_my_fix",
  gdef:    -1,
  restart: -1,   # -1 is this cheat's own "Disabled" value
)
```

With this set, the framework automatically compares "what's picked right now" against "what was
actually running when the game booted," and shows a small `[RESTART]` tag next to the row whenever
they disagree — for example, if the player just flipped it on but hasn't restarted since, or just
flipped it off but the old behavior is technically still active this session. You don't need to write
any of that comparison yourself — just tell it which value means "off."

If your cheat's live behavior is fully controlled by checking `$cheat_my_fix` *inside* the patched
method every time (like the `== 1` check in the §7 example), you generally don't need `restart:` at
all beyond marking the "off" value — the on/off switching itself is already live.

### 8a. Local/Global overrides (`global:`)

This is a separate feature from `gdef:` — it lets the player force a specific value for your cheat
from the Config > Edit Globals screen, independent of what's normally selected. Pass `global: true` or
`global: false` (whichever fits your cheat) to make it eligible:

```ruby
register_command(
  ...
  gdef:   false,
  global: false,   # opts this cheat into the Edit Globals screen
)
```

Most cheats don't need this — it's for settings a player might want to force on/off globally across
every save file regardless of that save's own setting. If you're not sure whether your cheat needs it,
it probably doesn't; just leave `global:` out entirely.

### 8b. Menu order (`order:`)

```ruby
register_command(
  ...
  order: 40,
)
```

A plain number controlling where your row sits in its `group:`, lowest first. Players can also
reorder rows themselves from the in-game Edit Menu Order screen, so treat your number as a starting
default, not a guarantee.

## 9. Hotkeys

```ruby
hotkey: { key: "F4" }
hotkey: { key: "Shift+F4", sound: :sound_WaterSpla }
```

Add this to any command. Players can also assign or change hotkeys themselves from the in-game menu,
so this is just a starting default. `sound:` is optional (a small sound effect on press).

## 10. Text and translations

Any `label:`/`help1:`/`help2:` (and, less commonly, `help3:`/`help4:` for extra help lines) you pass
as a plain string (not starting with `->`) is a *text key*, not the literal words shown to the player.
It points at an entry in a text file:

- `"modules/pregnancy:commands/preg"` → the file `text/ENG/modules/pregnancy.txt`, entry `commands/preg`
- `"menu:commands/misc"` → the file `text/ENG/menu.txt`, entry `commands/misc`

Text files are simple: a key, then the text for it, then a blank line, repeated:

```
commands/preg
Pregnancy

commands/difficulty
Pregnancy Difficulty
```

Add your new keys under `text/ENG/modules/<yourfile>.txt`. That's the one language folder you should
edit yourself — leave the other language folders alone, since those are typically translated
separately by someone else.

## 11. Checklist for a new module

1. Create `modules/YourModule.rb`.
2. Add a `FrameworkModule` header (§2) — optional for something tiny.
3. Decide: are you adding rows to an existing menu, a whole new screen linked from one (§4a), or your
   own row on the root Main Menu (§4b)?
4. Register your command(s) using the type table in §4.
5. If it's a cheat *setting* (not existing game data), add `gdef:` + a plain `$variable` `state:` and
   skip `action:` — persistence is automatic (§5).
6. If it edits existing game/actor data, write your own `action:` instead.
7. If your cheat changes existing game behavior rather than just adding a menu row, see §7 for how to
   do that safely, and §8 if it needs a restart to take effect.
8. Add text keys under `text/ENG/modules/yourmodule.txt` (§10).
9. Test with your cheat both on and off, including turning it on/off without restarting, to make sure
   the behavior (and any `[RESTART]` tag) matches what you expect.
10. Optional: set `order:` to control where it sits in the list (§8b), or `global:` if it should
    support a forced Local/Global override (§8a). Most cheats need neither.
