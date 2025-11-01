#===============================================================================
#  Cheat Utilities
#------------------------------------------------------------------------------
#  Provides utility functions for the Cheat Menu Framework.
#===============================================================================

#---------------------------------------------------------------------------
#  Checks if the game is currently in an active gameplay state
#---------------------------------------------------------------------------
module CheatUtils
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
  #Check if a game is loaded
  def self.ingame?
    return (!@outgame_scenes.any? {
      |outgame_scene|
      SceneManager.scene_is?(outgame_scene)
    } and $loading_screen.disposed?)
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
  alias_method :update_CHEATMENUFRAMEWORK, :update

  def update
    update_CHEATMENUFRAMEWORK
    $mod_cheats.cheat_triggers if CheatUtils.ingame?
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
