require 'system_helper'

describe SystemHelper do
  describe ".download_file(url:, to:)" do
    let (:url) { "https://github.com/sharkdp/bat/releases/download/v0.15.4/bat-musl_0.15.4_amd64.deb" }
    let (:to) { "$HOME/src/releases/bat-musl_0.15.4_amd64.deb" }

    it "raises StandardError when download_tool is invalid" do
      # Settings.instance.download_tool is nil
      expect { SystemHelper.download_file(url: url, to: to, download_tool: nil) }.to raise_error(StandardError)

      expect { SystemHelper.download_file(url: url, to: to, download_tool: 'no_such_tool') }.to raise_error(StandardError)
    end

    it "works OK using wget" do
      expected_command = %{wget -O "#{to}" "#{url}"}
      expect(SystemHelper).to receive("system").with(expected_command)

      SystemHelper.download_file(url: url, to: to, download_tool: :wget)
    end

    it "works OK using curl" do
      expected_command = %{curl -L --output "#{to}" "#{url}"}
      expect(SystemHelper).to receive("system").with(expected_command)

      SystemHelper.download_file(url: url, to: to, download_tool: 'curl')
    end
  end
end
