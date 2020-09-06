require "open3"

class SystemHelper
  class << self

    # downloads file using download tool (curl or wget)
    def download_file(url:, to:, download_tool:)
      case download_tool.to_s
      when 'curl'
        system %{curl -L --output "#{to}" "#{url}"}
      when 'wget'
        system %{wget -O "#{to}" "#{url}"}
      else
        raise "Invalid value for Settings.instance.download_tool: #{download_tool.inspect}"
      end
    end

    # checks if app is installed
    def installed?(app)
      system "which #{app} >/dev/null"
    end

    # Passes *commands to Open3.capture3 which passes it to system.
    # Returns stdout.
    #
    # Raises StandardError if system returns non 0 exit code (failure).
    # Error message contains exit code and stderr output.
    def capture_stdout_and_raise_on_error(*commands)
      stdout, stderr, status = Open3.capture3(*commands)

      unless status.success?
        raise "#{commands.join(" ")} failed with exit code #{status.exitstatus}.\n#{stderr}"
      end

      stdout
    end

    # detects operating system
    # returns one of :linux, :android, :darwin, :windows, ...
    #
    # based on https://github.com/rossmacarthur/install/blob/master/crate.sh
    def detect_os
      kernel_name = capture_stdout_and_raise_on_error("uname", "-s").strip

      case kernel_name
      when "Linux"
        os = capture_stdout_and_raise_on_error("uname", "-o")
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
  end
end
