# Cheat Framework: Module Guide

How to write a module for the Cheat Framework — how modules are discovered and loaded, how to register
commands in the main menu and submenus, and the quirks worth knowing before you copy-paste an example.

The best single file to read alongside this guide is
[`modules/Pregnancy.rb`](../modules/Pregnancy.rb) — it uses almost every command type and pattern
described here. It's referenced throughout.

---

## 1. How a module gets loaded

Drop a `.rb` file anywhere under `modules/` (subfolders are fine — `FrameworkLoader.discover` uses
`Dir.glob("**/*.rb")`). At startup (`__init__.rb`) the framework:

1. Discovers every `.rb` under `modules/` and reads its metadata (see §2).
2. Applies per-install overrides from `config/modules.ini` (enable/disable, load order).
3. Topologically sorts modules by `depends_on`, then by `order`.
4. `load`s each enabled module in that order, defining `FrameworkModule` as a temporary constant
   while loading, then removing it (`FrameworkLoader#load_enabled_modules`) — so don't rely on
   `FrameworkModule` existing outside your own module's top-level code.

Nothing needs to be registered manually — the file just needs to exist under `modules/`.

## 2. The `FrameworkModule` metadata block

Optional, but every real module in this mod defines one at the top of the file:

```ruby
FrameworkModule = {
  name:       "Pregnancy",   # Display name; also used to build Window_/Scene_ class names
  key:        :pregnancy,    # Unique symbol id for this module
  menu:       :PREGNANCY,    # Default submenu group (dict) this module's commands register under
  depends_on: [],            # Array of other modules' :key values that must load first
  enabled:    true           # Default enabled state (overridable per-install in modules.ini)
}
```

If you skip it, `FrameworkLoader` derives a default from the filename (`key` = downcased/underscored
basename, `order: 999`, `enabled: true`, `depends_on: []`) — fine for a one-off fix module that doesn't
register menu commands (see `Fixes.rb`'s style, though even it defines one for clarity).

`depends_on` matters when your module reads/patches something another module defines (e.g. relies on
`$framework.roleplay_mod?` gating, or aliases a method another module already aliased). If load order
doesn't matter, leave it `[]` and use `order` to influence menu position instead.

## 3. Two registration surfaces: MENU vs SUBMENU

Both live in `scripts/Menu.rb` under `module MenuFramework`:

- **`MenuFramework::MENU.register_command(...)`** — adds an entry to the framework's root menu
  (the one opened by F9). Used rarely; most modules hook into an *existing* root entry
  (`:MISC`, `:TOGGLES`, `:LONA`) rather than adding a new one. `InvEdit.rb` is an exception —
  it adds `Items`/`Weapons`/`Armors`/`Status` directly to the root menu.
- **`MenuFramework::SUBMENU.register_command(...)`** — adds a command *inside* a group/dict (a
  submenu screen). This is what you'll use almost all the time.

Both share an important convenience: if `FrameworkModule` is defined, missing `opts[:source]`,
`opts[:name]`, and (for SUBMENU) `opts[:group]` are auto-filled from it. That's why plain commands in
`Pregnancy.rb` don't bother repeating `source:` — but they *do* explicitly pass `group:` even when it
matches the module default, purely for readability.

### Registering a new submenu screen (a "scene")

To create a new screen (like Pregnancy's own page, reached from Character menu), register one command
of `type: :scene` that points *into* your dict, then register your actual commands *under* that dict:

```ruby
register_command(
  group:  :LONA,              # parent group this link appears in
  type:   :scene,
  key:    :pregnancy,
  label:  "modules/pregnancy:commands/preg",
  name:   "CheatMenuPregnancy",  # used to synthesize Window_CheatMenuPregnancy / Scene_CheatMenuPregnancy
  dict:   :PREGNANCY,           # the new group your sub-commands will register under
  order:  60
)
```

`MenuFramework.ensure_scene_and_window` (`scripts/Menu.rb`) builds the `Window_*`/`Scene_*` classes for
you the first time a `name:` is seen — you never hand-write a Window/Scene class for a standard command
list. You only write a custom Window/Scene class when the built-in editor UI can't do what you need
(see §8, "When you need more than a lambda").

## 4. Command types (`type:`)

All of these are `SUBMENU` registrations, `group:` is whatever dict the entry belongs to.

| type | Purpose | Required keys | Notes |
|---|---|---|---|
| `:action` | Runs a lambda, no persisted state | `action` | Fire-and-forget button |
| `:toggle` | On/off flag | `state`; `action` optional | See §5 |
| `:edit_num` | Editable number | `state`, `min`, `max` | Left/Right adjusts; Shift=x10, Ctrl=x100 |
| `:edit_list` | Cycle through a fixed list of values | `state`, `list` | Left/Right cycles |
| `:scene` | Navigates into a submenu | `name`, `dict` (or a pre-existing `scene`) | See §3 |
| `:info` | Read-only display row | `state` | No interaction; good for derived/computed values |

### `:action` — Pregnancy's "Clear"

```ruby
register_command(
  group:  :IMPREGNATE,
  type:   :action,
  key:    "Clear",
  label:  "modules/pregnancy:commands/clear",
  color:  -> { $game_player.actor.preg_level == 0 ? 8 : 0 },
  action: -> { $game_player.actor.cleanup_after_birth },
  enable: -> { !$cheat_protect_pregnancy },
  order:  80
)
```

### `:toggle` — Pregnancy's "Protect Pregnancy"

```ruby
register_command(
  group:  :PREGNANCY,
  type:   :toggle,
  key:    "Protect Pregnancy",
  label:  "modules/pregnancy:commands/protect",
  state:  "$cheat_protect_pregnancy",
  gdef:   false,
  help1:  "modules/pregnancy:command_help/protect",
  order:  30
)
```

### `:edit_num` — Pregnancy's "Seedbed"

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
  order:  20
)
```

`min`/`max` can be a literal or a `-> { }` proc for a dynamic bound (see Levels.rb: `max: -> {$game_player.actor.max_level}`).

### `:edit_list` — Pregnancy's "Pregnancy Difficulty"

```ruby
register_command(
  group:  :PREGNANCY,
  type:   :edit_list,
  key:    "Pregnancy Difficulty",
  label:  "modules/pregnancy:commands/difficulty",
  state:  "$cheat_pregnancy_difficulty",
  gdef:   -1,
  list:   [
            { key: -1, label: "[#{$framework.txt("modules/pregnancy:commands/diff_off")}]" },
            { key:  0, label: "[#{$framework.txt("modules/pregnancy:commands/diff_hard")}]" },
            { key:  1, label: "[#{$framework.txt("modules/pregnancy:commands/diff_hell")}]" },
            { key:  2, label: "[#{$framework.txt("modules/pregnancy:commands/diff_doom")}]" }
          ],
  order:  10
)
```

**Important gotcha:** unlike the top-level `label:` (a text key, resolved later at draw time via
`$framework.txt`), each `list:` entry's `label:` must already be a **resolved string** — call
`$framework.txt(...)` yourself inline, as shown above. It is displayed as-is, not re-resolved.

### `:info` — Pregnancy's "BabyRace" (conditionally shown)

```ruby
register_command(
  group:  :PREGNANCY,
  type:   :info,
  key:    "BabyRace",
  label:  "modules/pregnancy:info/babyRace",
  state:  "$game_player.actor.baby_race",
  hide:   -> { $game_player.actor.preg_level == 0 },
  order:  50
)
```

## 5. `gdef:` + `state:` — automatic persistence

If you pass both `gdef:` (a default value) and `state:` (a **string** of Ruby code that evaluates to
— and can be assigned to — the value, e.g. `"$cheat_protect_pregnancy"` or
`"$game_player.actor.stat['WombSeedBed']"`), the framework will, at registration time:

1. Read the saved value from `config/globals.ini` (or fall back to your `gdef:` default) and
   `eval` it into the variable named by `state`.
2. If you didn't supply your own `action:`, auto-generate one that writes the new value back into
   both the variable and `globals.ini`.

This is why `Protect Pregnancy` above needs no `action:` at all — toggling it, saving it, and
reloading it next session is all handled for you. `Pregnancy Difficulty` (`:edit_list`) works the
same way.

**When to skip `gdef:`:** anything that reflects live game state that's *already persisted by the
save file* — level, health, trait points, an NPC's story flag — should **not** use `gdef:`. Those
always need an explicit `action:` that edits the actual game object (see `Level`, `Seedbed`,
`Baby Health` above, or `Revive.rb`'s per-NPC actions). `gdef:` is for *cheat settings*, not
*game data*.

(Called `gdef:` — "global default" — rather than plain `global:` specifically because `global:` is
a different flag now; see §5a.)

## 5a. `global:` — Local/Global override eligibility

`global:` reads as a plain description of the command's *native* state — no double-negative to hold
in your head: `global: true` means the command natively behaves as Global, `global: false` means it
natively behaves as Local. Either way, it just marks the command as eligible to be forced the
opposite way from Config > Edit Globals; nothing changes until you actually do that.

A handful of `:toggle` commands read/write state that's *already* save-specific game data with no
`gdef:` at all (Appearance.rb's `Disable Dirt`, an `actStat` capped at 0 for "on") — normal and
correct, since that value already lives in the save file. That's natively Local, so it's flagged
`global: false` — eligible to be forced to behave the same way across every save instead:

```ruby
register_command(
  group:  :TOGGLES,
  type:   :toggle,
  key:    "Disable Dirt",
  state:  "$game_player.actor.actStat.get_stat('dirt', 3) == 0",
  global: false, # natively Local - eligible for Config > Edit Globals' override
  action: -> { ... }
)
```

This doesn't change the command itself at all — it's still a completely normal toggle in its own
submenu, unaffected either way. It just makes it show up in Config > Edit Globals
(`scripts/Controls.rb`), where each eligible command gets a Mode row (Z toggles Local/Global) and a
Value row right under it (the value to force). Two registries, both keyed `"GROUP.CommandKey"` like
`hotkey_defs`:

- `$framework.force_modes["TOGGLES.Disable Dirt"] = true` once you flip on the override (`false`/
  absent = inactive, the default — completely untouched, current behavior). This Hash always just
  means "is an override active" — what "active" *does* (force Global vs force Local) depends on the
  command's own `global: true/false` (see `FrameworkUtils.currently_global?`).
- The value to force lives in a *different* place depending on direction — see "Local vs Global
  storage" below. Either way it's lazily seeded from whatever the command's live state actually is
  the first time anything asks for it (`FrameworkUtils.force_value_for`), so there's nothing blank to
  look at, and it stays editable from Edit Globals even while the override isn't active, letting you
  pre-configure it before ever flipping the mode.

The opposite direction also works: `global: true` marks a `gdef:`-backed command (natively
install-wide) as forceable to behave per-save instead:

```ruby
register_command(
  key:    "Infinite Health",
  state:  "$cheat_infinite_health",
  gdef:   false,
  global: true, # natively Global - eligible to be forced per-save instead
  ...
)
```

**Local vs Global storage** — this is the part that isn't just "reuse the same Hash both ways":

- `global: false` (natively Local, forceable Global) — the value lives in `$framework.force_values`,
  persisted to `modules.ini`. Install-wide is exactly the right scope, since the whole point is "the
  one value to use on every save."
- `global: true` (natively Global, forceable Local) — the value lives in
  `$story_stats["CF_local_GROUP.CommandKey"]` instead, persisted *with the save itself* (`Story_Stats`
  is part of `DataManager`'s save payload — see `5_DataManager.rb`, `contents[:story] = $story_stats`).
  `modules.ini` would be the *wrong* scope here, since a different value per save is the entire goal.

**Applying a forced value** never needs to know what the command actually does, in either direction —
every command type already guarantees `state:` returns the current value and `action:` is an
arity-0/1/2 lambda that sets it (the same contract `Defaults.rb#save_editing` already dispatches on).
The two directions still apply differently, though:

- `global: false` (forcing toward Global) — `FrameworkUtils.force_command_value` calls `action:`
  directly (arity-dispatched), same as a normal edit would. Safe here because `Disable Dirt`-style
  commands don't have a `gdef:` at all — there's no `globals.ini` entry that this could ever step on.
- `global: true` (forcing toward Local) — `FrameworkUtils.quiet_set_command_value` assigns straight
  into the `$cheat_` variable via `state_str` (the raw `state:` string, stashed on the record
  alongside the wrapped getter) instead of calling `action:`. Deliberately bypasses the normal action,
  because that action *does* write to `globals.ini` for a `gdef:`-backed command — calling it here
  would silently overwrite the shared install-wide default with whatever this one save's forced-local
  value happens to be, corrupting it for every other save.

Both directions apply once per load/new game (`$framework.on_save_ready`, `scripts/Utils.rb`) and
immediately whenever the mode or value is changed from Edit Globals — never continuously, so neither
fights a player who manually changes the underlying command mid-session while the override is
inactive.

**Editing the Value row itself** also has to know the source's type: `:toggle` sources use Z (a plain
flip, `FrameworkUtils.toggle_force_value`); `:edit_num`/`:edit_list` sources use Left/Right instead
(`FrameworkUtils.adjust_force_value`, mirroring `Action_Window_Defaults#modify_variable`'s math, just
applied immediately rather than through a `start_editing`/`save_editing` session).

**Menu order:** `$framework.commands[:GLOBAL_OVERRIDES]` (built once by
`FrameworkUtils.build_global_overrides`, right after all modules finish registering) holds one entry
per `global: true/false` command, so Config > Edit Menu Order picks this group up and reorders it
like any other, no special-casing needed. Each entry only carries the "address"
(`source_group`/`source_key`) of its real command — `Window_CheatGlobalsList` draws both a Mode row
and a Value row per entry, but only the Mode row is ever independently ordered; the Value row is
always derived and drawn immediately after it, so the two can never drift apart from a reorder.

## 6. Hotkeys

Add a `hotkey:` to any command (any type):

```ruby
hotkey: { key: "F3" }
hotkey: { key: "Shift+F3" }
hotkey: { key: "F4", sound: :sound_WaterSpla }
```

This registers into `$framework.hotkey_defs["#{group}.#{key}"]`, which then gets merged with any
per-install override in `config/hotkeys.ini` (users can retarget or disable — set to `NONE` — without
touching code). `sound:` defaults to `:sys_ok` if omitted. Modifiers (`Shift+`, `Ctrl+`, `Alt+`) are
parsed automatically; see `FrameworkConfig#parse_hotkey`.

Multiple commands can safely share the same physical key (e.g. `F4` is shared by three different
Appearance toggles) — they'll all fire together on press, since hotkeys are matched by key +
modifier, not by uniqueness.

## 7. Visibility, enabling, and coloring

- **`hide:`** (bool or `-> {}`) — removes the row entirely from the list. Use for commands that are
  nonsensical in the current state (pregnancy fields when not pregnant).
- **`enable:`** (bool or `-> {}`, default `true`) — keeps the row visible but grays it out and appends
  the `"(Cheat Active)"` suffix (`menu:commands_status/locked`) when `false`/falsy. Use for "this is
  currently blocked by another toggle" (Pregnancy's `Clear` is disabled while `Protect Pregnancy` is on).
- **`color:`** (Numeric text-color index, `Color`, or `-> {}` returning either) — highlight a row
  conditionally. Convention in this codebase: `16` = active/matches-current-selection highlight (see
  the `Impregnate` race buttons highlighting the current `baby_race`), `8` = dimmed/informational.
- **`restart: true`** (bool, default `false`) — flags that this command's effect isn't fully live; using
  it sets `$framework.restart_needed = true` (`FrameworkUtils.mark_restart_needed`, `scripts/Utils.rb`),
  which shows a pulsing red warning in the Main Menu's help area until the game is relaunched. Add this
  when — and only when — your command's real effect is gated by an `if $some_var ... alias_method ...`
  (or a hard method redefinition) evaluated once at your module's load time, or bakes a cheat value into
  a class-level constant read once (see `Levels.rb`'s `Max Traits`, which copies `$cheat_variables_max_stat`
  into `LONA_STAT_DEFAULT` at load time — `LonaActorStat.new` only ever reads that snapshot, never the
  live variable). Don't add it just because a cheat *reads* a `$cheat_` variable inside a monkey-patched
  method — if the patch itself is unconditional and the check happens *inside* the method body (most of
  this codebase's toggles work this way — see `MainStats.rb`'s infinite-stat checks, re-evaluated every
  `hotkey_trigger` tick), the value change is picked up live and no flag is needed. When in doubt: would
  toggling this cheat off and back on, in the same session, actually do anything different the second
  time versus the first? If not, it needs `restart: true`.

## 8. When you need more than a lambda

Put a `module <YourModuleName>` (nested inside `module MenuFramework`, matching the pattern
`module Pregnancy` at the bottom of `Pregnancy.rb`) for logic too involved for an inline `->`:

```ruby
module MenuFramework
  module Pregnancy
    def self.impregnate(baby_race)
      actor = $game_player.actor
      actor.cleanup_after_birth
      actor.force_pregnancy(baby_race)
    end
  end
end
```

...then reference it from an `action:` as `-> { MenuFramework::Pregnancy.impregnate("Human") }`.

For anything beyond the standard editor UI (custom drawing, custom left/right behavior per row,
paging through game data), write your own `Window_*`/`Scene_*` and skip `ensure_scene_and_window` —
see `InvEdit.rb`'s `Window_CheatMenuItems` (browses `$data_items`/`$data_weapons`/`$data_armors`
directly with custom `draw_item`/`cursor_left`/`cursor_right`) for the pattern.

If you need a whole custom *flow* — more than one hand-written scene, navigated by hand instead of
through `register_command`'s `type: :scene` auto-wiring — see `scripts/Controls.rb`'s
`Scene_CheatMenuOrderGroups` → `Scene_CheatMenuOrderEdit` pair (a group picker that drills into a
per-group reorder screen). Pattern: define your own `Window_*`/`Scene_*` classes directly (skipping
`ensure_scene_and_window` entirely, since it only auto-generates classes that aren't already
defined), hand off data between them the same way the framework itself does — call
`SceneManager.call(scene)` then `SceneManager.scene.instance_variable_set(:@your_var, value)`
immediately after (safe because `start` doesn't run until later), and read it back with
`SceneManager.scene.instance_variable_get(:@your_var)` inside the next window's `initialize`. Don't
forget `FrameworkUtils.menu_scenes << YourScene` for each custom scene, or the F9 menu-toggle hotkey
won't recognize you're "in menu" while it's open.

**File-order gotcha (this one will bite you silently):** if any `register_command` call anywhere
uses `name: "YourWindowName"` matching one of your custom classes, that call must run *after* your
`class Window_YourWindowName` / `class Scene_YourWindowName` definitions in the file — not before.
`ensure_scene_and_window` only skips auto-generating a class if `Object.const_defined?` already
finds it; if your `register_command` call executes first (e.g. it's above your class definitions,
or in a different file that loads earlier), the framework silently builds its own generic version
first — one that mixes in `Action_Window_Defaults`, whose `initialize(160, 0)` sits between your
class and `Window_Command` once you "reopen" it. If your own `initialize` then calls `super(x, y)`
expecting to reach `Window_Command` directly, it hits that module's `initialize` instead and raises
`wrong number of arguments (2 for 0)`. Fix: define the classes first, register the command last (or
in a separate, later-loading step) — see the bottom of `scripts/Controls.rb` for the working order.

**Remembering cursor position on Cancel:** fully custom scenes get none of `Scene_Defaults`'
automatic "return to where you were" behavior, since that's implemented via `$framework.menu_stack`
(a shared breadcrumb array of `{menu:, symbol:, index:}` — see
`Scene_Defaults#save_action_window_state`/`restore_action_window_state` in `scripts/Defaults.rb`).
Replicate it yourself: push an entry (keyed by some symbol unique to your scene) right before
navigating away — both on Cancel *and* before drilling into a child scene — then look it up by that
same key and `select()` the matching row in your window's `start`. `scripts/Controls.rb`'s reorder scenes both
do this; note `Scene_CheatMenuOrderEdit` needs a *per-group* key (`:"edit_menu_order_#{@group}"`)
since that one scene class is reused for whichever group was picked — a plain fixed symbol would
have every group's reorder screen clobber the others' remembered position.

**Overlay windows update themselves — don't call `.update` yourself:** `Scene_Base#update_all_windows`
(`Data/Scripts/Frames/100_Scene_Base.rb`) auto-detects every instance variable on the scene that
`is_a?(Window)` and calls `.update` on it, every frame, with no registration step needed. If you add a
second window mid-scene (e.g. a confirmation overlay created inside a handler, after `start` already
ran), just assign it to an ivar (`@confirm_window = Window_Whatever.new`) and it's picked up
automatically next frame. Do **not** also add your own `update` override that calls
`@confirm_window.update` — that runs it twice per frame and risks double-processing input (a single Z
press registering as two `:ok` triggers). Same goes for cleanup: `dispose_all_windows` (called from
`terminate`) does the same sweep, so explicitly `.dispose`d + nilled-out windows (like the confirm
overlay once it's answered) are correctly skipped, but anything you forget to nil will get
double-disposed when the scene actually closes.

**Deferred writes with a forced Save/Discard choice:** for anything where you don't want every
individual edit hitting disk immediately, cache in memory and only persist on explicit confirmation.
`scripts/Controls.rb`'s reorder screen is the reference: `FrameworkUtils.start_menu_order_session` snapshots
current state once per session (guarded so re-entering a child scene and coming back doesn't
re-snapshot over your own pending edits), `mark_menu_order_dirty`/`menu_order_dirty?` track whether
anything changed, and leaving with unsaved changes shows a same-scene overlay window (see above) with
no `:cancel` handler — deliberately, so there's no way to dismiss it without picking Save or Discard.
Discard replays the snapshot back over live state; Save writes through and clears the session. Note
this is a **stricter** pattern than this game's own `ModManagerScene` (which just leaves Save/Revert as
always-available, non-blocking menu rows and writes to disk immediately on every edit) — don't assume
that's the house style everywhere; it's just what ModManager happens to do.

## 9. Hooking into the update loop

`CheatFramework#normal_trigger` (~1s) and `#slow_trigger` (~3s) are overridable hooks, called from
`Utils.rb`'s `hotkey_trigger` chain. To add periodic behavior (e.g. "protect pregnancy" continually
topping up baby health), alias-chain onto them from your module:

```ruby
class CheatFramework
  alias_method :slow_trigger_ProtectPreg, :slow_trigger
  def slow_trigger
    slow_trigger_ProtectPreg
    FrameworkUtils.protect_pregnancy
  end
end
```

Always alias to a **unique** method name (suffix it with your feature name) so multiple modules can
chain onto the same hook without clobbering each other. Same pattern applies to any other engine method
you need to monkey-patch (`alias_method :orig_foo, :foo`) — never redefine a shared engine method
without aliasing the original first.

## 10. Generating commands dynamically

For long, data-driven lists (all revivable unique NPCs, all summonable NPCs grouped by folder), loop
and call `register_command` per entry instead of hand-writing dozens of blocks. See `Revive.rb`:

```ruby
REVIVE_LIST.each do |char_key|
  register_command(
    group:  :REVIVE,
    type:   :action,
    key:    char_key,
    color:  -> { $story_stats[char_key] != -1 ? 8 : 0 },
    label:  "modules/revive:NPC/#{char_key}",
    action: -> { $story_stats[char_key] = 0 }
  )
end
```

Or `InvEdit.rb`'s `MenuFramework::Summons.build_dynamic_summons`, which builds nested dicts
(`SUMMON_<FOLDER>`) from game data at `DataManager.load_database` time — useful if the source list
isn't known until the database loads. Note `label: -> {char_key}` (a proc) is used instead of a text
key when the label *is* the raw data itself and isn't meant to be translated — `commands_from_group`
calls a Proc label directly instead of running it through `$framework.txt`.

## 11. Text / localization keys

Every `label:`, `help1:`-`help4:`, `menu1:`-`menu4:` you pass as a **string** is treated as a text key
and resolved via `$framework.txt(key)` → `$game_text["cheatframework:#{key}"]` at draw time. The key
format is `<relative path under text/<LANG>/, without .txt>:<entry name>`:

- `"modules/pregnancy:commands/preg"` → `text/<LANG>/modules/pregnancy.txt`, entry `commands/preg`
- `"menu:commands/misc"` → `text/<LANG>/menu.txt`, entry `commands/misc`

Text files are flat key/value pairs, one blank line apart:

```
commands/preg
Pregnancy

commands/difficulty
Pregnancy Difficulty
```

Add your new module's keys under `text/ENG/modules/<yourfile>.txt` at minimum (ENG is the safe
baseline); mirror into the other language folders (`CHT`, `ESP`, `KOR`, `MTL`, `RUS`, `UKR`) as you're
able, or leave it for translators — see `docs/README.md`'s "Known Issues" for the current translation
status.

## 12. Per-install overrides (no code changes needed)

Everything below lives in `config/` (as of the mod-folder relocation) and is safe for users to hand-edit:

- **`modules.ini`** — `[Module Load Overrides]` (`<key>.enabled = true/false`) and
  `[Load Order Overrides]` (`<key>.order = N`), keyed by your module's `FrameworkModule[:key]`; plus
  `[Menu Order Overrides]` (`<group>.<key> = N`), keyed exactly like hotkeys — see below. Also
  `[Force Mode Overrides]` for every `global: true/false` command's Local/Global state, and
  `[Force Value Overrides]` for the value to force *only* in the `global: false` direction — the
  `global: true` direction's forced value lives in `$story_stats` instead, with the save (§5a).
  Unlike everything else here, both of these actively prune entries for commands that no longer exist
  or are no longer flagged, rather than leaving them harmlessly unused.
- **`hotkeys.ini`** — `[Cheat Hotkeys]`, keyed by `<group>.<key>` exactly as registered; set a line to
  `NONE` to disable that hotkey.
- **`globals.ini`** — `[Global Variables]`, one entry per `gdef:`-backed command, keyed by the
  command's `key:`.

### Command display order (`order:`)

Every `register_command` call (MENU or SUBMENU) accepts `order:` (default `999` if omitted, matching
the module-load-order convention). Within a single `group:`/`dict:`, commands are drawn lowest-order
first; ties fall back to original registration order (which module loaded, and where in that file the
call appears) so two untouched commands never flap between runs.

At startup, right after all modules finish registering (`__init__.rb`, after `init_modules`),
`FrameworkConfig#init_order` runs: it applies any `<group>.<key>` override found in `modules.ini`'s
`[Menu Order Overrides]` section onto the live command record, then writes the *full* current set of
orders back out — so after first launch, every registered command's effective order value is visible
and editable in that file, the same way `hotkeys.ini` works for hotkeys. This means a user (or you,
testing) can reorder a submenu without touching code at all.

**Author-time gotcha:** `order:` only matters *within the same group*. Two modules contributing to the
same shared group (`:MISC`, `:TOGGLES`, `:PRIMARY`, `:LONA`, `:MAIN`...) can accidentally pick
the same number — when that happens, whichever module's `FrameworkModule[:order]` (or discovery order,
if unset) puts it in `$framework.commands` first wins the tie. If you're adding a command to a group
you don't own, check the other contributors' `order:` values first (`grep -n "order:" modules/*.rb`
filtered to the group you're targeting) rather than guessing a number.

Every command's registered `order:` is also stashed as `default_order:` (untouched by ini overrides or
live in-menu reordering). `scripts/Controls.rb`'s "Reset Menu Order to Default" uses this to restore every
`order:` to whatever the code originally specified and wipe `[Menu Order Overrides]`, live, no restart
— see `FrameworkConfig#reset_menu_order` in `scripts/Config.rb`. If you ever add another mechanism that
mutates `record[:order]` at runtime, remember `default_order:` is the one field it should never touch.

You don't need to touch these files yourself — they're populated automatically the first time your
command registers — but knowing the section/key naming helps when debugging "why didn't my setting
save" (usually: the `state:` wasn't a plain assignable global, or the `key:` collided with another
command in the same group).

## 13. Checklist for a new module

1. Create `modules/YourModule.rb`.
2. Add a `FrameworkModule` metadata hash (`name`, `key`, `menu`, `depends_on`, `enabled`).
3. If you're adding a whole new page, register one `type: :scene` command pointing at a new `dict:`;
   otherwise pick an existing `group:` (`:MISC`, `:TOGGLES`, `:LONA`, `:PREGNANCY`, etc.) to add
   into directly.
4. Register your commands under `MenuFramework::SUBMENU` using the type table in §4.
5. For cheat settings (not live game state), add `gdef:` + a plain-`$var` `state:` and skip writing
   an `action:` — persistence is automatic.
6. For anything editing live game/actor state, write an explicit `action:` (arity-1 lambda `->(v) {}`
   for `:edit_num`/`:edit_list`, arity-0 `-> {}` for `:toggle`/`:action`).
7. Add `hotkey:` only where it makes sense — check `docs/README.md`'s hotkey table to avoid clashing
   with an unrelated feature on the same key (shared keys are fine when they're conceptually related,
   like all "Infinite X" toggles on F5).
8. If your command's effect is gated by an `if $some_var` block evaluated once at load time (rather than
   checked live inside the patched method), add `restart: true` — see §7.
9. Add matching text keys under `text/ENG/modules/yourmodule.txt` (and other languages if you can).
10. Test with your module toggled on/off and reordered via `config/modules.ini` to make sure
    `depends_on` is set correctly if you rely on load order.
