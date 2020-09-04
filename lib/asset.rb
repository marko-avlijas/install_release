# Represents a single file (.tar.gz, .zip, .deb...) which is a release for
# certain architecture, os and distribution.
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

  def architecture
    @architecture ||= case name
                      when /arm/
                        :arm
                      when /i386/
                        :i386
                      when /i686/
                        :i686
                      when /(x86_64|amd64)/
                        :x86_64
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
            end
  end

  def distribution
    return nil unless os == :linux

    @distribution ||= if name =~ /\.deb$/
                        :debian
                      else
                        :unknown
                      end
  end
end

