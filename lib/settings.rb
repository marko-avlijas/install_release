require 'singleton'

class Settings
  include Singleton

  attr_accessor :preferred_download_tool, :download_dir
  attr_accessor :supported_oses, :supported_package_managers

  def set_defaults
    # can be :curl or :wget
    @preferred_download_tool = :curl

    # place where releases will be downloaded using download tool
    @download_dir = "$HOME/src/releases/"

    # if operating system is not on this list application will abort
    @supported_oses = [:linux]

    # assets for these package managers will be recognized
    @supported_package_managers = ["dpkg"]
    # TODO:
    # @supported_package_managers = ["apt", "apt-get", "dpkg", "dnf", "yum", "rpm"]
  end

  def clear
    instance_variables.each { |var| remove_instance_variable(var) }
  end
end
