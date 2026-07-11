#==============================================================================
# Config screens: Edit Menu Order, View Hotkeys, Edit Globals
#------------------------------------------------------------------------------
# Core framework tooling, not a cheat, so it lives in scripts/ (always
# loaded) rather than modules/. No FrameworkModule block; load order is just
# top-to-bottom in this file. Text keys live in text/<LANG>/menu.txt.
#==============================================================================

#==============================================================================
# Shared instructional footer for all three screens below
#==============================================================================
class Window_CheatOrderHelp < Window_Base
  def initialize(text)
    super(0, Graphics.height - 120, Graphics.width, 120)
    set_text(text)
  end

  def set_text(text)
    @text = text
    refresh
  end

  def refresh
    contents.clear
    MenuFramework.force_font(contents)
    draw_text_ex(4, 0, @text)
  end
end

#==============================================================================
# Forced Save/Discard prompt for unsaved menu reordering. No :cancel handler.
#==============================================================================
class Window_CheatOrderConfirm < Window_Command
  def initialize
    super((Graphics.width - window_width) / 2, (Graphics.height - window_height) / 2)
  end

  def window_width;  300; end
  def window_height; fitting_height(2); end

  def make_command_list
    add_command("Save Changes",    :save)
    add_command("Discard Changes", :discard)
  end
end

#==============================================================================
# Step 1: pick which menu (group) to reorder
#==============================================================================
class Window_CheatMenuOrderGroups < Window_Command
  include Window_ConfigList_Defaults

  # :MENU hotkey plumbing
  HIDDEN_GROUPS = [:NONE, :MENU]

  # Groups matching this prefix (SUMMON, SUMMON_HUMAN, SUMMON_WILD, ...) get
  # collapsed into a single "family" row instead of cluttering the top level.
  FAMILY_PREFIX = "SUMMON"

  def initialize
    super(0, 0)
    @filter = SceneManager.scene.instance_variable_get(:@filter)
    refresh
    select(0)
  end

  def make_command_list
    # Pinned first, irrespective of alphabetical order, and only at the top
    # (unfiltered) level - a reset doesn't belong scoped to one family view.
    add_command($framework.txt("menu:commands/reset_order"), :reset, true, nil) unless @filter

    groups = $framework.commands.keys.reject { |g| HIDDEN_GROUPS.include?(g) }
    groups = groups.select { |g| $framework.commands[g].is_a?(Hash) && !$framework.commands[g].empty? }

    if @filter
      groups.select { |g| in_family?(g, @filter) }
            .sort_by(&:to_s)
            .each { |group| add_command(group_label(group), :ok, true, group) }
    else
      family, singles = groups.partition { |g| in_family?(g, FAMILY_PREFIX) }
      singles.sort_by(&:to_s).each { |group| add_command(group_label(group), :ok, true, group) }
      unless family.empty?
        total = family.inject(0) { |sum, g| sum + $framework.commands[g].size }
        add_command("#{FAMILY_PREFIX} family (#{family.size} menus, #{total} commands)", :family, true, FAMILY_PREFIX)
      end
    end
  end

  def in_family?(group, prefix)
    group.to_s == prefix || group.to_s.start_with?("#{prefix}_")
  end

  def group_label(group)
    "#{group} (#{$framework.commands[group].size})"
  end

  def draw_item(index)
    force_content_font
    super
  end
end

class Scene_CheatMenuOrderGroups < Scene_MenuBase
  include Scene_ConfigList_Defaults

  def start
    super
    # Only true top-level entry starts a session (family drill-downs and
    # returning here from a child scene reuse whatever's already running).
    $framework.ini.start_menu_order_session if @filter.nil? && $framework.menu_order_snapshot.nil?

    @command_window = Window_CheatMenuOrderGroups.new
    @command_window.set_handler(:ok,     method(:open_group))
    @command_window.set_handler(:family, method(:open_family))
    @command_window.set_handler(:reset,  method(:perform_reset))
    @command_window.set_handler(:cancel, method(:on_cancel))
    @help_window = Window_CheatOrderHelp.new(
      @filter ? "Pick a #{@filter} menu to reorder.\nZ: Open   X: Back" : "Pick a menu to reorder, or reset it.\nZ: Select   X: Back"
    )
    restore_selection
  end

  # Each handler reactivates @command_window first (process_ok deactivates it).
  def open_group
    @command_window.activate
    group = @command_window.current_ext
    save_selection
    SceneManager.call(Scene_CheatMenuOrderEdit)
    SceneManager.scene.instance_variable_set(:@group, group) if SceneManager.scene
  end

  def perform_reset
    @command_window.activate
    $framework.ini.reset_menu_order
    $framework.ini.start_menu_order_session # re-baseline: nothing pending after a reset
    SndLib.sys_ok
    @command_window.refresh
    @command_window.select(0)
  end

  # Drill into the collapsed "family" row (e.g. SUMMON) - reopens this same
  # scene class, just filtered down to that family's groups.
  def open_family
    @command_window.activate
    prefix = @command_window.current_ext
    save_selection
    SceneManager.call(Scene_CheatMenuOrderGroups)
    SceneManager.scene.instance_variable_set(:@filter, prefix) if SceneManager.scene
  end

  # A dirty top-level exit forces a Save/Discard choice first.
  def on_cancel
    if @filter.nil? && $framework.ini.menu_order_dirty?
      show_confirm
    else
      save_selection
      return_scene
    end
  end

  def show_confirm
    @command_window.deactivate
    @help_window.set_text("You have unsaved menu order changes.\nPick one - there's no going back without choosing.")
    @confirm_window = Window_CheatOrderConfirm.new
    @confirm_window.set_handler(:save,    method(:confirm_save))
    @confirm_window.set_handler(:discard, method(:confirm_discard))
  end

  def confirm_save
    $framework.ini.save_order_to_ini
    $framework.ini.clear_menu_order_session
    SndLib.sys_ok
    leave_after_confirm
  end

  def confirm_discard
    $framework.ini.revert_menu_order_session
    SndLib.sys_buzzer
    leave_after_confirm
  end

  def leave_after_confirm
    @confirm_window.dispose
    @confirm_window = nil
    save_selection
    return_scene
  end

  # Distinct breadcrumb key for the unfiltered list vs. each family sub-view.
  def menu_key
    @filter ? :"edit_menu_order_family_#{@filter}" : :edit_menu_order
  end
end
FrameworkUtils.menu_scenes << Scene_CheatMenuOrderGroups

#==============================================================================
# Step 2: reorder the commands within the chosen group
#==============================================================================
class Window_CheatMenuOrderEdit < Window_Command
  include Window_ConfigList_Defaults

  def initialize
    super(0, 0)
    @group = SceneManager.scene.instance_variable_get(:@group)
    refresh
    select(0)
  end

  def make_command_list
    return unless @group
    dict = $framework.commands[@group]
    return unless dict
    FrameworkUtils.sorted_commands(dict).each do |key, record|
      name = FrameworkUtils.display_name_for(record, key)
      add_command(name, :ok, true, key)
    end
  end

  def draw_item(index)
    force_content_font
    rect = item_rect_for_text(index)
    contents.clear_rect(rect)
    change_color(normal_color, command_enabled?(index))
    draw_text(rect, command_name(index), 0)

    key    = @list[index][:ext]
    record = @group && $framework.commands[@group] ? $framework.commands[@group][key] : nil
    draw_text(rect, record[:order].to_s, 2) if record && record[:order]
  end

  # Swaps the selected command's position and renumbers the group.
  def cursor_left(wrap = false)
    move_selected(-1)
  end

  def cursor_right(wrap = false)
    move_selected(1)
  end

  def move_selected(direction)
    return unless @group
    dict = $framework.commands[@group]
    return unless dict

    ordered = FrameworkUtils.sorted_commands(dict)
    i = ordered.index { |key, _record| key == current_ext }
    return unless i

    j = i + direction
    return if j < 0 || j >= ordered.size

    ordered[i], ordered[j] = ordered[j], ordered[i]
    ordered.each_with_index { |(_key, record), idx| record[:order] = (idx + 1) * 10 }

    SndLib.play_cursor
    $framework.ini.mark_menu_order_dirty # cached in memory only - written on explicit confirm

    moved_key = current_ext
    refresh
    new_index = @list.index { |cmd| cmd[:ext] == moved_key }
    select(new_index || index)
  end
end

class Scene_CheatMenuOrderEdit < Scene_MenuBase
  include Scene_ConfigList_Defaults

  def start
    super
    @command_window = Window_CheatMenuOrderEdit.new
    @command_window.set_handler(:cancel, method(:return_to_groups))
    @help_window = Window_CheatOrderHelp.new(
      "Left/Right: Move up/down   X: Back to menu list"
    )
    restore_selection
  end

  def return_to_groups
    save_selection
    return_scene
  end

  # Distinct breadcrumb key per group (this scene class is reused for all of them).
  def menu_key
    :"edit_menu_order_#{@group}"
  end
end
FrameworkUtils.menu_scenes << Scene_CheatMenuOrderEdit

#==============================================================================
# View Hotkeys: every bound command and its key (clear only)
#==============================================================================
class Window_CheatHotkeyList < Window_Command
  include Window_ConfigList_Defaults

  MAIN_MENU_KEY = "MENU.Main Menu"

  # F1/F12/F10 excluded (blocked/reserved); F5/F6 excluded (RolePlay-S
  # QuickSave/QuickLoad while active). M is a free letter key, not an F-key.
  MAIN_MENU_CANDIDATES = %w[F2 F3 F4 F7 F8 F9 F11 M]

  def initialize
    super(0, 0)
    @editing_main_menu = false
    @pending_index = 0
  end

  def make_command_list
    # Pinned first, always. Not a plain :ok row like the rest - see
    # toggle_main_menu_edit for why changing this one is a bigger deal.
    add_command(main_menu_label, :locked, true, MAIN_MENU_KEY)

    $framework.hotkey_defs.each do |full_key, data|
      next if data[:key].nil? || data[:key].to_s.upcase == "NONE" # nothing to show/clear anymore
      record = resolve_record(full_key)
      next unless record

      name = FrameworkUtils.display_name_for(record, record[:key])
      add_command(name, :ok, true, full_key)
    end
  end

  def main_menu_label
    "Main Menu (more options in Keybind menu)"
  end

  def resolve_record(full_key)
    group_key, cmd_key = full_key.split('.', 2)
    dict = $framework.commands[group_key.to_sym]
    return nil unless dict
    dict[cmd_key] || dict[cmd_key.to_sym]
  end

  def draw_item(index)
    force_content_font
    rect = item_rect_for_text(index)
    contents.clear_rect(rect)

    full_key = @list[index][:ext]

    if full_key == MAIN_MENU_KEY
      draw_main_menu_row(rect, index)
      return
    end

    change_color(normal_color)
    draw_text(rect, command_name(index), 0)

    data = $framework.hotkey_defs[full_key]
    key_text = (data && data[:key]) || "NONE"
    reserved = HotkeyReserved.info_for(key_text)
    if reserved
      change_color(text_color(8))
      draw_text(rect, "#{key_text} (also: #{reserved[:label]})", 2)
    else
      change_color(normal_color)
      draw_text(rect, key_text, 2)
    end
  end

  def draw_main_menu_row(rect, index)
    current = FrameworkUtils.current_menu_toggle_key || "NONE"
    change_color(@editing_main_menu ? text_color(16) : text_color(8))
    draw_text(rect, command_name(index), 0)
    draw_text(rect, @editing_main_menu ? MAIN_MENU_CANDIDATES[@pending_index] : current, 2)
  end

  # Rebind for the Main Menu hotkey: cycle candidates, second press confirms.
  def toggle_main_menu_edit
    if @editing_main_menu
      confirm_main_menu_edit
    else
      start_main_menu_edit
    end
  end

  def start_main_menu_edit
    current = FrameworkUtils.current_menu_toggle_key || "F9"
    @pending_index = MAIN_MENU_CANDIDATES.index(current) || MAIN_MENU_CANDIDATES.index("F9")
    @editing_main_menu = true
    SndLib.play_cursor
    refresh
    update_warning_text
  end

  def cancel_main_menu_edit
    @editing_main_menu = false
    SndLib.sys_cancel
    refresh
    update_warning_text
  end

  def confirm_main_menu_edit
    new_key = MAIN_MENU_CANDIDATES[@pending_index]
    @editing_main_menu = false

    # Single source of truth, shared with the vanilla Key Binds menu.
    $framework.ini.apply_menu_toggle_key(new_key)

    # Wipe any cheat hotkey already sitting on the new base key (any modifier).
    wiped = false
    $framework.hotkey_defs.each do |full_key, data|
      next unless data[:key]
      next unless data[:key].to_s.split('+').last.upcase == new_key
      data[:key] = "NONE"
      wiped = true
    end
    if wiped
      $framework.ini.save_hotkeys_to_ini
      $framework.ini.build_hotkey_map
    end

    SndLib.sys_ok
    refresh
    update_warning_text
  end

  def update_warning_text
    return unless SceneManager.scene.respond_to?(:set_main_menu_warning)
    if @editing_main_menu
      SceneManager.scene.set_main_menu_warning(
        "WARNING: this changes which key opens this menu - pick carefully!\n" \
        "Previewing: #{MAIN_MENU_CANDIDATES[@pending_index]}   " \
        "Left/Right: change   Z: confirm   X: cancel"
      )
    else
      SceneManager.scene.set_main_menu_warning(nil)
    end
  end

  def cursor_up(wrap = false)
    super unless @editing_main_menu
  end

  def cursor_down(wrap = false)
    super unless @editing_main_menu
  end

  # Also locked while editing (reachable via L/R shoulder or mouse wheel).
  def cursor_pageup
    super unless @editing_main_menu
  end

  def cursor_pagedown
    super unless @editing_main_menu
  end

  def cursor_left(wrap = false)
    if @editing_main_menu
      SndLib.play_cursor
      @pending_index = (@pending_index - 1) % MAIN_MENU_CANDIDATES.size
      refresh
      update_warning_text
    else
      super
    end
  end

  def cursor_right(wrap = false)
    if @editing_main_menu
      SndLib.play_cursor
      @pending_index = (@pending_index + 1) % MAIN_MENU_CANDIDATES.size
      refresh
      update_warning_text
    else
      super
    end
  end

  def process_cancel
    if @editing_main_menu
      cancel_main_menu_edit
    else
      super
    end
  end
end

class Scene_CheatHotkeyList < Scene_MenuBase
  include Scene_ConfigList_Defaults

  def menu_key; :set_hotkeys; end

  def start
    super
    @command_window = Window_CheatHotkeyList.new
    @command_window.set_handler(:ok,     method(:clear_selected))
    @command_window.set_handler(:locked, method(:on_main_menu_locked))
    @command_window.set_handler(:cancel, method(:on_cancel))
    @base_help_text = "Read-only - to assign or change one, use C in the command's own menu.\nZ: Clear   X: Back"
    @help_window = Window_CheatOrderHelp.new(@base_help_text)
    restore_selection
  end

  def set_main_menu_warning(text)
    @help_window.set_text(text || @base_help_text)
  end

  def on_main_menu_locked
    @command_window.activate # process_ok already deactivated - reactivate before doing anything
    @command_window.toggle_main_menu_edit
  end

  def clear_selected
    # Reactivate - process_ok deactivates before calling the handler.
    @command_window.activate

    full_key = @command_window.current_ext
    return unless $framework.hotkey_defs[full_key]

    $framework.hotkey_defs[full_key][:key] = "NONE"
    $framework.ini.save_hotkeys_to_ini
    $framework.ini.build_hotkey_map # live immediately - no restart needed
    SndLib.sys_cancel

    @command_window.refresh
    clamp_selection # the cleared row just vanished from the list - keep the cursor in bounds
  end

  def on_cancel
    save_selection
    return_scene
  end
end
FrameworkUtils.menu_scenes << Scene_CheatHotkeyList

#--------------------------------------------------------------------------
# Local/Global override engine (Config > Edit Globals)
#--------------------------------------------------------------------------
module FrameworkUtils
  # force_modes["GROUP.CommandKey"] = true/false, is an override active.
  def self.force_mode_for(group, key)
    $framework.force_modes["#{group}.#{key}"] == true
  end

  # Whether the command is currently, effectively behaving as Global.
  def self.currently_global?(group, key, record)
    active = force_mode_for(group, key)
    record && record[:global] == true ? !active : active
  end

  def self.current_command_value(record)
    return nil unless record && record[:state]
    value = record[:state].call
    record[:type] == :toggle ? !!value : value
  end

  def self.local_value_story_key(full_key)
    "CF_local_#{full_key}"
  end

  # global: false -> force_values, modules.ini. global: true -> $story_stats.
  def self.force_value_for(group, key, record)
    full_key = "#{group}.#{key}"
    if record && record[:global] == false
      return $framework.force_values[full_key] if $framework.force_values.key?(full_key)
      seed = current_command_value(record)
      $framework.force_values[full_key] = seed
      $framework.ini.save_force_values_to_ini
      seed
    else
      story_key = local_value_story_key(full_key)
      return $story_stats[story_key] if $story_stats.data.key?(story_key)
      seed = current_command_value(record)
      $story_stats[story_key] = seed
      seed
    end
  end

  def self.set_force_value(group, key, record, new_value)
    full_key = "#{group}.#{key}"
    if record && record[:global] == false
      $framework.force_values[full_key] = new_value
      $framework.ini.save_force_values_to_ini
    else
      $story_stats[local_value_story_key(full_key)] = new_value
    end
  end

  def self.toggle_force_mode(group, key, record)
    full_key = "#{group}.#{key}"
    $framework.force_modes[full_key] = !force_mode_for(group, key)
    $framework.ini.save_force_modes_to_ini
    apply_force_mode(group, key, record)
  end

  def self.toggle_force_value(group, key, record)
    set_force_value(group, key, record, !force_value_for(group, key, record))
    apply_force_mode(group, key, record)
  end

  # Left/Right editing for a :edit_num/:edit_list-sourced Value row.
  def self.adjust_force_value(group, key, record, direction, multiplier = 1)
    current = force_value_for(group, key, record)
    new_value = case record[:type]
                when :edit_num
                  min = record[:min].is_a?(Proc) ? record[:min].call : (record[:min] || 0)
                  max = record[:max].is_a?(Proc) ? record[:max].call : (record[:max] || 999)
                  [[current.to_i + direction * multiplier, min].max, max].min
                when :edit_list
                  list = record[:list] || []
                  return if list.empty?
                  idx = (list.index { |i| i[:key] == current } || 0)
                  list[(idx + direction) % list.size][:key]
                else
                  current
                end
    set_force_value(group, key, record, new_value)
    apply_force_mode(group, key, record)
  end

  # Applies a forced value via the command's own action: (arity-dispatched).
  def self.force_command_value(record, desired)
    return unless record && record[:state] && record[:action]
    return if current_command_value(record) == desired
    case record[:action].arity
    when 1 then record[:action].call(desired)
    when 2 then record[:action].call(record[:key], desired)
    else        record[:action].call
    end
  end

  # Assigns the variable directly via state_str, bypassing action: (which
  # would also write globals.ini for a gdef:-backed command).
  def self.quiet_set_command_value(record, desired)
    return unless record && record[:state_str]
    return if current_command_value(record) == desired
    eval("#{record[:state_str]} = #{desired.inspect}")
  end

  # Applies one command's configured override - a no-op while inactive.
  def self.apply_force_mode(group, key, record)
    return unless record && !record[:global].nil?
    return unless force_mode_for(group, key)
    desired = force_value_for(group, key, record)
    if record[:global] == false
      force_command_value(record, desired)
    else
      quiet_set_command_value(record, desired)
    end
  end

  def self.apply_force_modes
    $framework.commands.each do |group, dict|
      next unless dict.is_a?(Hash)
      dict.each do |key, record|
        next unless record.is_a?(Hash)
        apply_force_mode(group, key, record)
      end
    end
  end

  # Builds $framework.commands[:GLOBAL_OVERRIDES], one entry per global:
  # true/false command, addressed by source_group/source_key.
  def self.build_global_overrides
    overrides = {}
    order = 0
    $framework.commands.each do |group, dict|
      next if group == :GLOBAL_OVERRIDES
      next unless dict.is_a?(Hash)
      dict.each do |key, record|
        next unless record.is_a?(Hash) && !record[:global].nil?
        order += 10
        overrides["#{group}.#{key}"] = {
          source_group:  group,
          source_key:    key,
          # Live lookup for Edit Menu Order's display.
          label:         -> {
            source = $framework.commands[group] && $framework.commands[group][key]
            FrameworkUtils.display_name_for(source, key)
          },
          order:         order,
          default_order: order
        }
      end
    end
    $framework.commands[:GLOBAL_OVERRIDES] = overrides
  end
end

#==============================================================================
# Edit Globals: Mode row (Local/Global) plus a derived Value row
#==============================================================================
class Window_CheatGlobalsList < Window_Command
  include Window_ConfigList_Defaults

  def initialize
    super(0, 0)
  end

  def make_command_list
    FrameworkUtils.sorted_commands(overrides_dict).each do |full_key, override|
      source = source_record(override)
      next unless source
      name = "#{FrameworkUtils.display_name_for(source, override[:source_key])} [#{override[:source_group]}]"
      add_command(name, :toggle_mode, true, full_key)
      # Indentation is applied here, not baked into the text key.
      add_command("    #{$framework.txt("menu:mode/value_row")}", :toggle_value, true, full_key)
    end
  end

  def overrides_dict
    $framework.commands[:GLOBAL_OVERRIDES] || {}
  end

  def override_for(full_key)
    overrides_dict[full_key]
  end

  def source_record(override)
    dict = override && $framework.commands[override[:source_group]]
    dict && dict[override[:source_key]]
  end

  def draw_item(index)
    force_content_font
    rect = item_rect_for_text(index)
    contents.clear_rect(rect)

    full_key = @list[index][:ext]
    override = override_for(full_key)
    source   = source_record(override)
    return unless override && source

    group, key = override[:source_group], override[:source_key]
    active = FrameworkUtils.force_mode_for(group, key) # is an override currently applying at all

    case @list[index][:symbol]
    when :toggle_mode
      change_color(normal_color)
      draw_text(rect, command_name(index), 0)
      showing_global = FrameworkUtils.currently_global?(group, key, source)
      draw_text(rect, showing_global ? $framework.txt("menu:mode/global") : $framework.txt("menu:mode/local"), 2)
    when :toggle_value
      change_color(active ? normal_color : text_color(8))
      draw_text(rect, command_name(index), 0)
      value = FrameworkUtils.force_value_for(group, key, source)
      draw_text(rect, format_force_value(source, value), 2)
    end
  end

  def format_force_value(record, value)
    case record[:type]
    when :toggle
      value ? $framework.txt("menu:cheat_toggle/on") : $framework.txt("menu:cheat_toggle/off")
    when :edit_list
      item = (record[:list] || []).find { |i| i[:key] == value }
      item ? item[:label] : value.to_s
    else
      value.to_s
    end
  end

  # Left/Right only edits an :edit_num/:edit_list Value row; falls through otherwise.
  def cursor_left(wrap = false)
    return super unless adjustable_value_row?
    adjust_value_row(-1)
  end

  def cursor_right(wrap = false)
    return super unless adjustable_value_row?
    adjust_value_row(1)
  end

  def adjustable_value_row?
    entry = @list[index]
    return false unless entry && entry[:symbol] == :toggle_value
    source = source_record(override_for(entry[:ext]))
    source && [:edit_num, :edit_list].include?(source[:type])
  end

  def adjust_value_row(direction)
    full_key = current_ext
    override = override_for(full_key)
    source   = source_record(override)
    return unless override && source
    SndLib.play_cursor
    FrameworkUtils.adjust_force_value(override[:source_group], override[:source_key], source, direction, edit_value_multiply)
    refresh
  end

  def edit_value_multiply
    multi = 1
    multi *= 10  if Input.press?(Input::KEYMAP[:SHIFT])
    multi *= 100 if Input.press?(Input::KEYMAP[:CONTROL])
    multi
  end
end

class Scene_CheatGlobalsList < Scene_MenuBase
  include Scene_ConfigList_Defaults

  def menu_key; :edit_globals; end

  def start
    super
    @command_window = Window_CheatGlobalsList.new
    @command_window.set_handler(:toggle_mode,  method(:toggle_mode))
    @command_window.set_handler(:toggle_value, method(:toggle_value))
    @command_window.set_handler(:cancel,       method(:on_cancel))
    @help_window = Window_CheatOrderHelp.new(
      "Z: Local/Global (top row) or toggle the forced value (bottom row - :toggle sources only,\n" \
      "Left/Right instead for a number/list)\nX: Back"
    )
    restore_selection
  end

  def toggle_mode
    @command_window.activate # process_ok already deactivated - reactivate before doing anything
    with_addressed_source(method(:apply_toggle_mode))
  end

  def toggle_value
    @command_window.activate
    with_addressed_source(method(:apply_toggle_value))
  end

  def apply_toggle_mode(group, key, source)
    FrameworkUtils.toggle_force_mode(group, key, source)
    SndLib.sys_ok
  end

  # Z only flips a :toggle source; numeric/list ones use Left/Right instead.
  def apply_toggle_value(group, key, source)
    return SndLib.sys_buzzer unless source[:type] == :toggle
    FrameworkUtils.toggle_force_value(group, key, source)
    SndLib.sys_ok
  end

  def with_addressed_source(block)
    full_key = @command_window.current_ext
    override = @command_window.override_for(full_key)
    return unless override
    source = @command_window.source_record(override)
    return unless source
    block.call(override[:source_group], override[:source_key], source)
    @command_window.refresh
  end

  def on_cancel
    save_selection
    return_scene
  end
end
FrameworkUtils.menu_scenes << Scene_CheatGlobalsList

#==============================================================================
# Reset Config Settings, Yes/No gated. Hotkeys/menu order/Local-Global
# overrides reset live; module enable/order and cheat defaults need a restart.
#==============================================================================
class Window_CheatResetSettings < Window_Command
  def initialize
    super((Graphics.width - window_width) / 2, (Graphics.height - window_height) / 2)
  end

  def window_width;  340; end
  def window_height; fitting_height(2); end

  def make_command_list
    add_command("Reset Everything", :reset)
    add_command("Cancel",           :cancel)
  end
end

class Scene_CheatResetSettings < Scene_MenuBase
  def start
    super
    @help_window = Window_CheatOrderHelp.new(
      "Hotkeys, menu order, and Local/Global overrides reset immediately.\n" \
      "Module enable/order and cheat variable defaults need a restart."
    )
    @command_window = Window_CheatResetSettings.new
    @command_window.set_handler(:reset,  method(:perform_reset))
    @command_window.set_handler(:cancel, method(:return_scene)) # covers the Cancel row and X
  end

  def perform_reset
    $framework.ini.reset_all_settings
    $framework.ini.reset_hotkeys_live
    $framework.ini.reset_menu_order
    $framework.ini.reset_force_overrides
    $framework.restart_needed = true
    SndLib.sys_ok
    return_scene
  end
end
FrameworkUtils.menu_scenes << Scene_CheatResetSettings

#==============================================================================
# Register the four entry points
#==============================================================================
module MenuFramework
  module SUBMENU
    register_command(
      group:  :CONFIG,
      type:   :scene,
      key:    :set_hotkeys,
      label:  "menu:commands/set_hotkeys",
      help1:  "menu:command_help/set_hotkeys1",
      help2:  "menu:command_help/set_hotkeys2",
      name:   "CheatHotkeyList",
      order:  20
    )
    register_command(
      group:  :CONFIG,
      type:   :scene,
      key:    :edit_menu_order,
      label:  "menu:commands/edit_order",
      help1:  "menu:command_help/edit_order1",
      help2:  "menu:command_help/edit_order2",
      name:   "CheatMenuOrderGroups",
      order:  30
    )
    register_command(
      group:  :CONFIG,
      type:   :scene,
      key:    :edit_globals,
      label:  "menu:commands/edit_globals",
      help1:  "menu:command_help/edit_globals1",
      help2:  "menu:command_help/edit_globals2",
      name:   "CheatGlobalsList",
      order:  40
    )
    register_command(
      group:  :CONFIG,
      type:   :scene,
      key:    :reset_all_settings,
      label:  "menu:commands/reset_all_settings",
      help1:  "menu:command_help/reset_all_settings1",
      help2:  "menu:command_help/reset_all_settings2",
      name:   "CheatResetSettings",
      order:  50
    )
  end
end
