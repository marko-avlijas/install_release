require_relative 'settings'

class Installer
  attr_reader :repo, :tag, :release, :asset
  attr_reader :system_info, :package_managers, :selected_asset

  def initialize(options)
    @repo = options[:git]
    @tag = options[:tag]
  end

  def install
    detect_system

    @release = Release.new(repo: repo, tag: tag)
    release.get_info

    select_asset
    download_asset

    install_asset

  rescue Release::NotFoundError => e
    puts
    puts e.message
    puts "Hint: maybe you mispelled the repository name?"
    10
  rescue Release::RepoHasNoReleasesError => e
    puts
    puts e.message
    11
  end

  def detect_system
    puts "\nDetecting system...\n\n"
    @system_info = DetectSystem.call
    puts system_info.report
    abort "Can't continue" unless system_info.supported?
  end

  def select_asset
    @selected_asset = SelectAsset.call(cpu: system_info.cpu_type,
                                       os: system_info.os,
                                       package_managers: system_info.package_managers,
                                       release: release)
    puts "\n\n"
    puts selected_asset.report
    abort "Can't continue" unless selected_asset.success?
  end

  def download_asset
  end

  def install_asset
    0
  end
end
