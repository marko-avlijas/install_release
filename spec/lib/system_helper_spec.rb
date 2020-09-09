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

  describe ".installed?" do
    it "detects when app is not installed" do
      allow(SystemHelper).to receive("system").with("which wget >/dev/null").and_return(false)

      expect(SystemHelper.installed?("wget")).to be false
    end

    it "detects when app is installed" do
      allow(SystemHelper).to receive("system").with("which wget >/dev/null").and_return(true)

      expect(SystemHelper.installed?("wget")).to be true
    end
  end

  describe ".capture_stdout_and_raise_on_error" do
    context "command returns 0 (success)" do
      it "returns captured stdout" do
        output = SystemHelper.capture_stdout_and_raise_on_error("which", "bash")
        expect(output).to match(/bash\n$/)
      end
    end

    context "command returns non 0 (error)" do
      it "raises StandardError with message containing exit code and stderr" do
        error_code_message = /uname --racket failed with exit code 1./
        stderr_message = /uname: /

        expect do
          SystemHelper.capture_stdout_and_raise_on_error("uname", "--racket")
        end.to raise_error(StandardError, error_code_message)

        expect do
          SystemHelper.capture_stdout_and_raise_on_error("uname", "--racket")
        end.to raise_error(StandardError, stderr_message)
      end
    end
  end
end
