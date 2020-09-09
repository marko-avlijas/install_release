class Installer
  attr_reader :repo, :tag, :release, :asset
  attr_reader :os, :cpu_type, :download_tool, :package_managers, :selected_asset

  def initialize(repo:, tag:)
    @repo = repo
    @tag = repo
  end

  def install
    @relase = Release.new repo: repo, tag: tag

    # TODO: parse options
    Settings.instance.set_defaults

    detect_system

    select_asset
    download_asset

    status_code = install_asset
    exit status_code
  end

  def detect_system
    system_info = DetectSystem.call
    puts system_info.report
    abort "Can't continue" unless system_info.supported?
  end

  def select_asset
    @selected_asset = SelectAsset.call(cpu: cpu_type, os: os, package_managers: package_managers, release: release)
    puts selected_asset.report
    abort "Can't continue" unless selected_asset.success?
  end

  def download_asset
  end

  def install_asset
  end
end
