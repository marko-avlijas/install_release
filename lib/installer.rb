class Installer
  attr_reader :repo, :tag, :release, :asset
  attr_reader :os, :cpu_type, :download_tool, :package_managers

  def initialize(repo:, tag:)
    @repo = repo
    @tag = repo
  end

  def install
    @relase = Release.new repo: repo, tag: tag

    # TODO: parse options
    Settings.instance.set_defaults

    detect_os
    abort "OS #{os.inspect} is not supported" unless Settings.instance.supported_oses.include?(@os)

    detect_cpu_type
    abort "Couldn't detect cpu architecture" if cpu_type.nil?

    detect_system_download_tool
    abort "Couldn't find curl or wget" if download_tool.nil?

    detect_package_managers

    select_asset
    download_asset

    status_code = install_asset
    exit status_code
  end

  def detect_os
    @os = SystemHelper.detect_os
  end

  def detect_system_download_tool
    tool1 = Settings.instance.preferred_download_tool
    tool2 = ([:curl, :wget] - [tool1]).first

    if SystemHelper.installed?(tool1)
      @download_tool = tool1
    elsif SystemHelper.installed?(tool2)
      @download_tool = tool2
    end
  end

  def detect_package_managers
    @package_managers = Settings.instance.supported_package_managers.map { |pm| pm.to_s }
                                .select do |package_manager|
                                  SystemHelper.installed?(package_manager)
                                end
  end

  def detect_cpu_type
    @cpu_type = SystemHelper.detect_cpu_type
  end

  def select_asset
  end

  def download_asset
  end

  def install_asset
    if asset.package_manager == "dpkg"
      SystemHelper.dpkg_install
    end
  end
end
