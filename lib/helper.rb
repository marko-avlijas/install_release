class Helper
  class << self
    def download_file(url:, to:)
      download_tool = Settings.instance.download_tool.to_s

      case download_tool
      when 'curl'
        system %{curl -L --output "#{to}" "#{url}"}
      when 'wget'
        system %{wget -O "#{to}" "#{url}"}
      else
        raise "Invalid value for Settings.instance.download_tool: #{download_tool.inspect}"
      end
    end
  end
end
