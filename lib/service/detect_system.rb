require 'service/callable'
require 'system_helper'

# Detects system, cpu type & tools avaialable
#
# Example usage:
#
# system_info = DetectSystem.call
# puts system_info.report
# abort "Can't continue" unless system_info.supported?
#
class DetectSystem
  extend Callable

  attr_reader :os, :cpu_type, :download_tool, :package_managers

  # in normal usage use call, this is intended for tests
  def initialize(os: nil, cpu_type: nil, download_tool: nil, package_managers: nil)
    @os = os
    @cpu_type = cpu_type
    @download_tool = download_tool
    @package_managers = package_managers
  end

  def call
    detect_os
    detect_cpu_type
    detect_system_download_tool
    detect_package_managers
  end

  def supported?
    @supported ||= (os_supported? && !cpu_type.nil? && !download_tool.nil?)
  end

  def os_supported?
    Settings.instance.supported_oses.include?(@os)
  end

  def report
    <<~TEXT
      Operating system: #{os == :unknown_os ? "unknown" : os.to_s.capitalize}
      CPU type: #{cpu_type == :unknown_cpu ? "unknown" : cpu_type}
      Download tool: #{download_tool.nil? ? "not found (looking for curl or wget)" : download_tool}
    TEXT
  end

  # detects operating system
  # returns one of :linux, :android, :darwin, :windows, ...
  #
  # based on https://github.com/rossmacarthur/install/blob/master/crate.sh
  def detect_os
    kernel_name = SystemHelper.capture_stdout_and_raise_on_error("uname", "-s").strip

    @os = case kernel_name
          when "Linux"
            os = SystemHelper.capture_stdout_and_raise_on_error("uname", "-o")
            (os =~ /Android/) ? :android : :linux
          when "Darwin"
            :darwin
          when /MINGW/, /MSYS/, /CYGWIN/
            :windows
          when "FreeBSD"
            :freebsd
          when "NetBSD"
            :netbsd
          when "DragonFly"
            :dragonfly
          else
            :unknown_os
          end
  end

  # detects system architecture
  # returns :x86_64, :i686, arm, or :unknown_cpu
  # there are more details to arm processors but I don't think this will be used on arm
  #
  # based on https://github.com/rossmacarthur/install/blob/master/crate.sh
  def detect_cpu_type
    machine = SystemHelper.capture_stdout_and_raise_on_error("uname", "-m").strip

    @cpu_type = case machine
                when /x86_64/, /x86-64/, /x64/, /amd64/
                  :x86_64
                when /i386/, /i486/, /i686/, /i786/, /x86/
                  :i686
                when /xscale/, /arm/, /aarch64/
                  :arm
                else
                  :unknown_cpu
                end
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
end
