class SystemHelper
  class << self
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
  end
end
