require 'settings'
require 'helper'

describe Helper do
  describe ".download_file(url:, to:)" do
    let (:url) { "https://github.com/sharkdp/bat/releases/download/v0.15.4/bat-musl_0.15.4_amd64.deb" }
    let (:to) { "$HOME/src/releases/bat-musl_0.15.4_amd64.deb" }

    it "raises StandardError when Settings.download_tool is invalid" do
      # Settings.instance.download_tool is nil
      expect { Helper.download_file(url: url, to: to) }.to raise_error(StandardError)

      Settings.instance.download_tool = :no_such_tool
      expect { Helper.download_file(url: url, to: to) }.to raise_error(StandardError)
    end

    it "works OK using wget" do
      Settings.instance.download_tool = :wget
      expected_command = %{wget -O "#{to}" "#{url}"}
      expect(Helper).to receive("system").with(expected_command)

      Helper.download_file(url: url, to: to)
    end

    it "works OK using curl" do
      Settings.instance.download_tool = 'curl'
      expected_command = %{curl -L --output "#{to}" "#{url}"}
      expect(Helper).to receive("system").with(expected_command)

      Helper.download_file(url: url, to: to)
    end
  end
end
