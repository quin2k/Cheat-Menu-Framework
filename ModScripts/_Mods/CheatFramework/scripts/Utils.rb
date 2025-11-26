#===============================================================================
#  Cheat Utilities
#------------------------------------------------------------------------------
#  Provides utility functions for the Cheat Framework.
#===============================================================================

#---------------------------------------------------------------------------
#  Checks if the game is currently in an active gameplay state
#---------------------------------------------------------------------------
module FrameworkUtils
  class << self
    attr_accessor :menu_scenes
  end
  #List of Scenes classed as being out of game
  @outgame_scenes = [
    ModManagerScene,
    Scene_MapTitle,
    Scene_AdultContentWarning,
    Scene_FirstTimeSetup,
    Scene_Title,
    Scene_TitleOptions,
    Scene_TitleOptInputMenu,
    Scene_ACHlistMenu,
    Scene_Credits,
    Scene_Menu,
    Scene_File,
    Scene_Save,
    Scene_Load_OnGameMenu,
    Scene_Load
  ]
  @menu_scenes = []
  #Check if a game is loaded
  def self.ingame?
    return (!@outgame_scenes.any? {
      |outgame_scene|
      SceneManager.scene_is?(outgame_scene)
    } and $loading_screen.disposed?)
  end

  def self.in_menu?
    @menu_scenes.any? { |scene_class| SceneManager.scene_is?(scene_class) }
  end

  def self.custom_state_edit(state, new_value)
    actor = $game_player.actor
    state_id = state
    change = new_value - (actor.stat[state_id] || 0)
    if change == 0
      return
    elsif change < 0
      change.abs.times { actor.remove_state_stack(state_id) }
    elsif change > 0
      change.times { actor.add_state(state_id) }
    end
  end

end

#---------------------------------------------------------------------------
#  Overrides to remove debug massaging in SceneManager
#---------------------------------------------------------------------------
class Scene_Base
  def return_scene
    SceneManager.return
  end
end

module SceneManager
  def self.call(scene_class)
		@stack.push(@scene)
		@scene = scene_class.new
	end

  def self.return
    @scene = @stack.pop
  end
end

#---------------------------------------------------------------------------
#  Window Base adjustment to reduce padding
#---------------------------------------------------------------------------
class Window_Base < Window
  def new_line_x
    standard_padding / 2
  end
end

#---------------------------------------------------------------------------
#  Scene Base update override to include cheat triggers
#---------------------------------------------------------------------------
class Scene_Base
  alias_method :update_Framework, :update

  def update
    update_Framework
    $framework.hotkey_trigger if FrameworkUtils.ingame?
  end
end

#Set update rate for other triggers.
class CheatFramework
  alias_method :hotkey_trigger_TIMER, :hotkey_trigger

  def hotkey_trigger
    hotkey_trigger_TIMER
    frame = Graphics.frame_count
    @last_normal_check ||= 0
    @last_slow_check ||= 0

    # Every ~1 second
    if frame - @last_normal_check >= 40
      @last_normal_check = frame
      normal_trigger
    end

    # Every ~3 seconds
    if frame - @last_slow_check >= 120
      @last_slow_check = frame
      slow_trigger
    end
  end
end

#---------------------------------------------------------------------------
#  Add extra triggerable keys to Input module
#---------------------------------------------------------------------------
module Input
  F1 = [KEYMAP[:F1]]
  F2 = [KEYMAP[:F2]]
  F3 = [KEYMAP[:F3]]
  F4 = [KEYMAP[:F4]]
  Agrave = [KEYMAP[:Agrave]]
end
