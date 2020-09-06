require 'singleton'

class Settings
  include Singleton

  attr_accessor :download_tool, :download_dir

  def set_defaults
    # can be :curl or :wget
    @download_tool = :curl

    # place where releases will be downloaded using download tool
    @download_dir = "$HOME/src/releases/"
  end
end
