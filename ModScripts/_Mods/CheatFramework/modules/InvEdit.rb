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


#--------------------------------------------------------------------------
# Window_CheatMenuItems
#--------------------------------------------------------------------------

class Window_CheatMenuItems < Window_Command
  include Action_Window_Defaults
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
