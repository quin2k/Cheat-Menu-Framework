FrameworkModule = {
  name:     "Inventory Editor",
  key:      :invedit, 
  order:    50,
  menu:     :NONE
}

#Register Menu Command
MenuFramework::MENU.register_command(
  type:   :scene,
  key:    :items,
  label:  "modules/invedit:commands/items", 
  name:   "CheatMenuItems",
  order:  20
)

MenuFramework::MENU.register_command(
  type:   :scene,
  key:    :weapons,
  label:  "modules/invedit:commands/weapons", 
  name:   "CheatMenuItems",
  order:  21
)

MenuFramework::MENU.register_command(
  type:   :scene,
  key:    :armors,
  label:  "modules/invedit:commands/armors", 
  name:   "CheatMenuItems",
  order:  22
)

MenuFramework::MENU.register_command(
  type:   :scene,
  key:    :status,
  label:  "modules/invedit:commands/status", 
  name:   "CheatMenuStatus",
  order:  30
)

MenuFramework::SUBMENU.register_command(
  type:  :action,
  group: :NPC,
  key:   "Bank Anywhere",
  label: "modules/invedit:commands/bank",
  hotkey: {key: "F2"},
  action: -> { 
      SceneManager.goto(Scene_BankStorage)
      SceneManager.scene.prepare(System_Settings::STORAGE_BANK)
  })

MenuFramework::SUBMENU.register_command(
  type:   :scene,
  group:  :NPC,
  key:    :summon,
  label:  "modules/invedit:commands/summon", 
  name:   "CheatMenuSummon",
  dict:   :SUMMON,
  order:  40
)

#--------------------------------------------------------------------------
# Cached Item/Weapon/Armor/Status Lists
#--------------------------------------------------------------------------
# Pre-filtered once instead of re-scanning the raw data every time.
module MenuFramework
  module InvEditCache
    extend self

    attr_reader :items, :weapons, :armors, :statuses

    def build
      @items    = build_group($data_items,   "I%03d:")
      @weapons  = build_group($data_weapons, "W%03d:")
      @armors   = build_group($data_armors,  "A%03d:")
      @statuses = $data_StateName.each_pair.reject do |k, v|
        v.nil? || k.nil? || v.name == "" || v.name == "nil" || v.name == "DataState:nil/name" ||
          v.description == "" || v.description == "nil" || v.description == "DataState:nil/description"
      end.to_a
    end

    def build_group(group, fmt)
      (1...group.size).each_with_object([]) do |i, list|
        item = group[i]
        next if item.nil? || item.item_name.nil? || item.item_name == "" || item.description == ""
        list << [sprintf(fmt, i), item]
      end
    end
  end
end

class << DataManager
  alias_method :cf_invedit_load_mod_database, :load_mod_database
  def load_mod_database
    cf_invedit_load_mod_database
    MenuFramework::InvEditCache.build
  end
end

#--------------------------------------------------------------------------
# Menu Loading Fix
#--------------------------------------------------------------------------
# Only draws the current page of rows instead of the whole list
module MenuFramework
  module VirtualScrollWindow
    def contents_height
      page_row_max * item_height
    end

    def top_row
      @virtual_top_row || 0
    end

    def top_row=(row)
      row = 0 if row < 0
      row = row_max - 1 if row > row_max - 1
      changed = row != top_row
      @virtual_top_row = row
      self.oy = 0 # bitmap only ever holds one page - never pan it
      refresh_visible_rows if changed
    end

    def draw_all_items
      first = top_row
      last  = [top_row + page_row_max, item_max].min - 1
      (first..last).each { |i| draw_item(i) } if last >= first
    end

    def item_rect(index)
      rect = Rect.new
      rect.width  = item_width
      rect.height = item_height
      rect.x = index % col_max * (item_width + spacing)
      rect.y = (index / col_max - top_row) * item_height
      rect
    end

    def refresh
      @virtual_top_row = 0
      self.oy = 0
      super
    end

    def refresh_visible_rows
      contents.clear
      draw_all_items
    end
  end
end

#--------------------------------------------------------------------------
# Window_CheatMenuItems
#--------------------------------------------------------------------------

class Window_CheatMenuItems < Window_Command
  include Action_Window_Defaults
  include MenuFramework::VirtualScrollWindow
  def initialize
    super
    symbol = SceneManager.scene.instance_variable_get(:@menu_symbol)
    set_type(symbol)
  end

  #--------------------------------------------------------------------------
  # set_type
  #--------------------------------------------------------------------------
  def set_type(type)
    @type = type
    refresh
    select(0)
  end

  #--------------------------------------------------------------------------
  # make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    case @type
    when :items
      group = $data_items
      fmt = "I%03d:"
    when :weapons
      group = $data_weapons
      fmt = "W%03d:"
    else
      group = $data_armors
      fmt = "A%03d:"
    end
    for i in 1...group.size
      text = sprintf(fmt, i)
      add_command(text, :item, true, group[i]) if !(group[i].nil? or group[i].item_name.nil? or group[i].item_name == "" or group[i].description == "")
    end
  end

  #--------------------------------------------------------------------------
  # draw_item
  #--------------------------------------------------------------------------
  def draw_item(index)
    MenuFramework.force_font(contents) if contents
    contents.clear_rect(item_rect_for_text(index))
    rect = item_rect_for_text(index)
    item = @list[index][:ext]
    name = item.name
    change_color(normal_color, $game_party.item_number(item) > 0)
    if $game_party.item_number(item) > 0 && item.name == ""
      change_color(knockout_color)
      name = "#{$framework.txt("menu:info/alert")}"
    end
    draw_text(rect, command_name(index))
    rect.x += text_size(command_name(index)).width
    rect.width -= text_size(command_name(index)).width
    draw_icon(item.icon_index, rect.x, rect.y, $game_party.item_number(item) > 0)
    rect.x += 24
    rect.width -= 24
    draw_text(rect, $game_text[name])
    text = sprintf("x%s", $game_party.item_number(item))
    draw_text(rect, text, 2)
  end

  def load_initial
    return if @list.empty?
    text = prep_desc($game_text[@list[0][:ext].description])
    override_help_window_text(text)
  end

  def refresh_help_window
    return if @list.empty?
    entry = @list[@index]
    return unless entry && entry[:ext] && entry[:ext]
    desc_key = entry[:ext].description
    text = prep_desc($game_text[desc_key])
    override_help_window_text(text)
  end

  def prep_desc(desc)
    return "" if desc.nil?
    return "" if desc.end_with?("/description")
    return "" if desc.end_with?("nil/nil")
    return desc
  end


  #--------------------------------------------------------------------------
  # cursor_right
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    SndLib.play_cursor
    $game_party.gain_item(current_ext, Input.press?(Input::KEYMAP[:SHIFT]) ? 10 : 1)
    $game_party.gain_item(current_ext, Input.press?(Input::KEYMAP[:CTRL]) ? 99 : 0)
    draw_item(index)
  end

  #--------------------------------------------------------------------------
  # cursor_left
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    SndLib.play_cursor
    $game_party.lose_item(current_ext, Input.press?(Input::KEYMAP[:SHIFT]) ? 10 : 1)
    $game_party.lose_item(current_ext, Input.press?(Input::KEYMAP[:CTRL]) ? 99 : 0)
    draw_item(index)
  end
end # Window_CheatMenuItems


class Window_CheatMenuStatus < Window_Command
  include Action_Window_Defaults
  include MenuFramework::VirtualScrollWindow

  def make_command_list
    $data_StateName.each_pair do |k, v|
      if v != nil and k != nil
        add_command("", :drawStat, true, [k, v]) if !(v.name == "" or v.name == "nil" or v.name == "DataState:nil/name" or v.description == "" or v.description == "nil" or v.description == "DataState:nil/description")
      end
    end
  end

  def drawStat
  end

  def draw_item(index)
    MenuFramework.force_font(contents) if contents
    contents.clear_rect(item_rect_for_text(index))
    rect = item_rect_for_text(index)
    item = @list[index][:ext][1]
    name = @list[index][:ext][0]
    stack = $game_player.actor.state_stack(name)
    change_color(normal_color, stack)
    draw_icon(item.icon_index, rect.x, rect.y, stack)
    rect.x += 24
    rect.width -= 24
    if item.name.empty?
      draw_text(rect, name)
    else
      draw_text(rect, $game_text[item.name])
    end
    text = sprintf("%s/%s", stack, item.max_stacks)
    draw_text(rect, text, 2)
  end

  def cursor_right(wrap = false)
    SndLib.play_cursor
    $game_player.actor.add_state(current_ext[0])
    draw_item(index)
  end

  def cursor_left(wrap = false)
    SndLib.play_cursor
    $game_player.actor.remove_one_state(current_ext[0])
    $game_player.actor.update_state_portrait_stat(current_ext[0])
    draw_item(index)
  end

  def refresh_help_window
    return if @list.empty?
    entry = @list[@index]
    return unless entry && entry[:ext] && entry[:ext][1]
    desc_key = entry[:ext][1].description
    text = prep_desc($game_text[desc_key])
    override_help_window_text(text)
  end

  def prep_desc(desc)
    return "" if desc.nil?
    return "" if desc.end_with?("/description")
    return "" if desc.end_with?("nil/nil")
    begin
      text = desc.dup
      text.sub!(/^\\}\\n\f\\}/, "\\}")  # Remove leading \n\f\}
      text.sub!(/^\\}\\}/, "\\}") # Remove double \}
      text.sub!(/^\\}\\n/, "\\}") # Remove leading \n
      text.gsub!("\\n", " ")  # Replace \n with space
      text.strip # Remove leading/trailing spaces
    rescue => e
      p "Got #{e.message}"
      ""
    end
  end
end

class Game_Actor
  def remove_one_state(state_id)
    state_id = $data_StateName[state_id].id if state_id.is_a?(String)
    return prp "erase_state #{state_id} not found", 1 if !state_id
    @states.delete_at(@states.index(state_id) || @states.length) ## Line added to remove only one instance.
    return if state?(state_id) ## Line added to prevent a stack from bugging.
    # @state_turns.delete(state_id)
    @state_steps.delete(state_id)
  end
end

module MenuFramework
  module Summons
    extend self

    def build_dynamic_summons
      summonable_keys = []

      # Collect summonable NPC/event keys
      $data_npcs.each do |npc|
        next unless npc
        summonable_keys << npc[0]
      end

      # Compute folders (same logic as old compute_folders)
      folder_map = Hash.new { |h, k| h[k] = [] }

      $data_EventLib.each_key do |key|
        next unless summonable_keys.include?(key)

        camel = key.split(/(?=[A-Z])/).reject(&:empty?)
        next if camel.empty?

        #folder = camel.first
        # Rename some folders for better grouping
        folder = {"Swine"=>"Wild","Player"=>"Baby","Deepone"=>"Fishkind","Gang"=>"Human"}.fetch(camel.first, camel.first)

        folder_map[folder] << key
      end

      # Register folder scenes under :SUMMON
      folder_map.keys.sort.each_with_index do |folder, i|
        dict = :"SUMMON_#{folder.upcase}"

        MenuFramework::SUBMENU.register_command(
          group:  :SUMMON,
          type:   :scene,
          key:    folder,
          label:  -> {folder},
          name:   "CheatMenuSummon_#{folder}",
          dict:   dict,
          order:  (i + 1) * 10
        )

        # Register each NPC inside the folder dictionary
        folder_map[folder].sort.each_with_index do |npc_key, j|
          MenuFramework::SUBMENU.register_command(
            group:  dict,
            type:   :action,
            key:    npc_key,
            label:  -> {npc_key},
            order:  (j + 1) * 10,
            action: -> {
              begin
                $game_map.summon_event(
                  npc_key,
                  $game_player.x,
                  $game_player.y
                )
              rescue => e
                p "Summon error #{npc_key}: #{e.message}"
              end
            }
          )
        end
      end
    end
  end
end

# Run builder at load time
class << DataManager
  alias_method :cf_summon_load_db, :load_database
  def load_database
    cf_summon_load_db
    MenuFramework::Summons.build_dynamic_summons
  end
end