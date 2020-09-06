require 'settings'
require 'installer'

describe Installer do
  subject { described_class.new(repo: "sharkdp/fd", tag: "latest") }

  it "#detect_os detects current os (without mocking / stubbing)" do
    # sorry other os users
    expect([:linux, :darwin, :freebsd, :dragonfly]).to include(subject.detect_os)
  end

  it "#detect_cpu_type detects cpu type (without mocking / stubbing)" do
    expect(subject.detect_cpu_type).to eq(:x86_64)
  end

  describe "#detect_system_download_tool" do
    context "preferred_download_tool is available" do
      it "detects curl" do
        Settings.instance.preferred_download_tool = :curl
        expect(SystemHelper).to receive(:system).with(/which curl/).and_return(true)

        subject.detect_system_download_tool
        expect(subject.download_tool).to eq(:curl)
      end

      it "detects wget" do
        Settings.instance.preferred_download_tool = :wget
        expect(SystemHelper).to receive(:system).with(/which wget/).and_return(true)

        subject.detect_system_download_tool
        expect(subject.download_tool).to eq(:wget)
      end
    end

    context "preferred_download_tool is not available" do
      it "detects wget when curl is not available" do
        Settings.instance.preferred_download_tool = :curl
        expect(SystemHelper).to receive(:system).with(/which curl/).and_return(false)
        expect(SystemHelper).to receive(:system).with(/which wget/).and_return(true)

        subject.detect_system_download_tool
        expect(subject.download_tool).to eq(:wget)
      end

      it "detects curl when wget is not available" do
        Settings.instance.preferred_download_tool = :wget
        expect(SystemHelper).to receive(:system).with(/which wget/).and_return(false)
        expect(SystemHelper).to receive(:system).with(/which curl/).and_return(true)

        subject.detect_system_download_tool
        expect(subject.download_tool).to eq(:curl)
      end

      it "sets download_tool to nil if neither curl or wget are available" do
        Settings.instance.preferred_download_tool = :curl
        expect(SystemHelper).to receive(:system).with(/which wget/).and_return(false)
        expect(SystemHelper).to receive(:system).with(/which curl/).and_return(false)

        subject.detect_system_download_tool
        expect(subject.download_tool).to be nil
      end
    end
  end

  describe "#detect_package_managers" do
    before (:context) do
      Settings.instance.supported_package_managers = [:apt, :"apt-get", "dpkg", "dnf", "yum", :rpm]
    end
    after(:context) { Settings.instance.clear }

    it "on ubuntu it detects apt, apt-get and dpkg" do
      expect(SystemHelper).to receive(:installed?).with("apt").and_return(true)
      expect(SystemHelper).to receive(:installed?).with("apt-get").and_return(true)
      expect(SystemHelper).to receive(:installed?).with("dpkg").and_return(true)
      expect(SystemHelper).to receive(:installed?).with("dnf").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("yum").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("rpm").and_return(false)

      subject.detect_package_managers
      expect(subject.package_managers).to eq(["apt", "apt-get", "dpkg"])
    end

    it "on fedora it detects dnf, yum and rpm" do
      expect(SystemHelper).to receive(:installed?).with("apt").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("apt-get").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("dpkg").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("dnf").and_return(true)
      expect(SystemHelper).to receive(:installed?).with("yum").and_return(true)
      expect(SystemHelper).to receive(:installed?).with("rpm").and_return(true)

      subject.detect_package_managers
      expect(subject.package_managers).to eq(["dnf", "yum", "rpm"])
    end

    it "sets package_managers to [] if no recognized package managers are installed" do
      expect(SystemHelper).to receive(:installed?).with("apt").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("apt-get").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("dpkg").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("dnf").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("yum").and_return(false)
      expect(SystemHelper).to receive(:installed?).with("rpm").and_return(false)

      subject.detect_package_managers
      expect(subject.package_managers).to eq([])
    end
  end
end

