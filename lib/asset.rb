# Represents a single file (.tar.gz, .zip, .deb...) which is a release for
# certain cpu_type, os and distribution.
class Asset
  attr_reader :raw_data

  # either set raw_data (as parsed json) or name and download_url
  def initialize(raw_data: nil, name: nil, download_url: nil)
    @raw_data = raw_data
    @name = name
    @download_url = download_url
  end

  def name
    @name ||= raw_data["name"]
  end

  def download_url
    @download_url ||= raw_data["browser_download_url"]
  end

  def to_s
    <<~TEXT
      Name:         #{name}
      Download URL: #{download_url}
    TEXT
  end

  def cpu_type
    @cpu_type ||= case name
                      when /arm/
                        :arm
                      when /i386/, /i686/
                        :i686
                      when /(x86_64|x86-64|x64|amd64)/
                        :x86_64
                      else
                        :unknown_cpu
                      end
  end

  def os
    @os ||= case name
            when /windows/
              :windows
            when /(apple|darwin)/
              :darwin
            when /linux/
              :linux
            when /\.deb$/
              :linux
            else
              :unknown_os
            end
  end

  def package_manager
    case name
    when /\.deb$/
      'dpkg'
    else
      :none
    end
  end
end

