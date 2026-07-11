FrameworkModule = {
  name:       "Unlock Gallery",
  key:         :unlock_gallery,
  menu:       :TOGGLES,
  order:      90
}

MenuFramework::SUBMENU.register_command(
    type:   :toggle,
    key:    "Unlock Gallery",
    label:  "modules/others:commands/gallery",
    state:  "$cheat_unlock_gallery",
    gdef:   false,
    order:  90
  )

# Bypasses the gallery achievement check by rewriting the recollection room's
# own event conditions, so it keeps working even if new events are added.
class Game_Map
  alias setup_event_hack_UnlockGallery setup_event_hack
  def setup_event_hack
    setup_event_hack_UnlockGallery
    return unless $cheat_unlock_gallery

    if @name == "NoerRecRoom" #Map075
      override_matching(/^if DataManager.get_rec_constant/,"if true")
      override_matching(/^if DataManager.get_constant/,"if true")
    end
  end

  # Replaces matching script-command conditions across every event on the map.
  def override_matching(condition_str, replacement_str, page_index = 0)
    @map.events.each_value do |event|
      next unless event && event.pages
      page = event.pages[page_index]
      next unless page && page.list.is_a?(Array)

      page.list.each_with_index do |command, idx|
        next unless command && [355, 655].include?(command.code)
        next unless command.parameters.any? do |p|
          p.is_a?(String) && (
            condition_str.is_a?(Regexp) ? (p =~ condition_str) : p.include?(condition_str)
          )
        end
        page.list[idx] = RPG::EventCommand.new(355, 0, [replacement_str])
      end
    end
  end
end
