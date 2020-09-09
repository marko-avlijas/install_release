require 'service/detect_system'

describe DetectSystem do
  describe "#os_supported?" do
    it "returns true when os is Settings.instance.supported_oses" do
      Settings.instance.supported_oses = [:linux, :darwin]

      subject.instance_variable_set(:@os, :linux)
      expect(subject.os_supported?).to be true

      subject.instance_variable_set(:@os, :windows)
      expect(subject.os_supported?).to be false
    end
  end

  describe "#supported?" do
    before(:context) do
      @old_supported_oses = Settings.instance.supported_oses
      Settings.instance.supported_oses = [:linux, :darwin]
    end
    after(:context) { Settings.instance.supported_oses = @old_supported_oses }

    it "returns true when os is supproted and cpu and download tool are not nil" do
      subject = described_class.new(os: :linux, cpu_type: :i686, download_tool: "wget")
      expect(subject.supported?).to be true
    end

    it "returns false when os is not supported" do
      subject = described_class.new(os: :windows, cpu_type: :i686, download_tool: "wget")
      expect(subject.supported?).to be false
    end

    it "returns false when cpu_type is nil" do
      subject = described_class.new(os: :windows, cpu_type: nil, download_tool: "wget")
      expect(subject.supported?).to be false
    end

    it "returns false when download_tool is nil" do
      subject = described_class.new(os: :windows, cpu_type: :i686, download_tool: nil)
      expect(subject.supported?).to be false
    end
  end

  describe "#report" do
    it "when everything is found" do
      subject = described_class.new(os: :linux, cpu_type: :x86_64, download_tool: "wget")
      report = subject.report

      expect(report).to match(/Operating system: Linux/)
      expect(report).to match(/CPU type: x86_64/)
      expect(report).to match(/Download tool: wget/)
    end

    it "when everything is unknown/missing" do
      subject = described_class.new(os: :unknown_os, cpu_type: :unknown_cpu, download_tool: nil)
      report = subject.report

      expect(report).to match(/Operating system: unknown/)
      expect(report).to match(/CPU type: unknown/)
      expect(report).to match(/Download tool: not found/)
    end
  end

  describe ".detect_os" do
    let (:success_status) { double("Success status", :success? => true) }

    def stub_uname_s_to_return(return_value)
      allow(Open3).to receive(:capture3).with("uname", "-s").and_return(return_value)
    end

    def stub_uname_o_to_return(return_value)
      allow(Open3).to receive(:capture3).with("uname", "-o").and_return(return_value)
    end

    it "detects Linux" do
      stub_uname_s_to_return ["Linux\n", "", success_status]
      stub_uname_o_to_return ["GNU/Linux\n", "", success_status]

      expect(subject.detect_os).to eq(:linux)
    end

    it "detects Android" do
      stub_uname_s_to_return ["Linux\n", "", success_status]
      stub_uname_o_to_return ["Android\n", "", success_status]

      expect(subject.detect_os).to eq(:android)
    end

    it "detects Darwin" do
      stub_uname_s_to_return ["Darwin\n", "", success_status]

      expect(subject.detect_os).to eq(:darwin)
    end

    it "detects FreeBSD" do
      stub_uname_s_to_return ["FreeBSD\n", "", success_status]

      expect(subject.detect_os).to eq(:freebsd)
    end

    it "detects NetBSD" do
      stub_uname_s_to_return ["NetBSD\n", "", success_status]

      expect(subject.detect_os).to eq(:netbsd)
    end

    it "detects DragonFly" do
      stub_uname_s_to_return ["DragonFly\n", "", success_status]

      expect(subject.detect_os).to eq(:dragonfly)
    end

    it "detects Windows" do
      stub_uname_s_to_return ["MINGWblah\n", "", success_status]
      expect(subject.detect_os).to eq(:windows)

      stub_uname_s_to_return ["MSYSblah\n", "", success_status]
      expect(subject.detect_os).to eq(:windows)

      stub_uname_s_to_return ["CYGWINblah\n", "", success_status]
      expect(subject.detect_os).to eq(:windows)
    end

    it "returns :unknown_os if can't recognize os" do
      stub_uname_s_to_return ["Hey Ho\n", "", success_status]

      expect(subject.detect_os).to eq(:unknown_os)
    end
  end

  describe ".detect_cpu_type" do
    let (:success_status) { double("Success status", :success? => true) }

    def stub_uname_m_to_return(return_value)
      allow(Open3).to receive(:capture3).with("uname", "-m").and_return(return_value)
    end

    it "detects :x86_64" do
      aggregate_failures do
        ["x86_64", "x86-64", "blahx64blah", "amd64"].each do |uname_m|
          stub_uname_m_to_return [uname_m, "", success_status]

          expect(subject.detect_cpu_type).to eq(:x86_64), "Expected #{uname_m} to get detected as :x86_64"
        end
      end
    end

    it "detects :i686" do
      aggregate_failures do
        ["blahx86blah", "i386", "i486", "i686", "i786"].each do |uname_m|
          stub_uname_m_to_return [uname_m, "", success_status]

          expect(subject.detect_cpu_type).to eq(:i686), "Expected #{uname_m} to get detected as :i686"
        end
      end
    end

    it "detects :arm" do
      aggregate_failures do
        ["xscale", "arm", "armv61", "armv71", "armv81", "aarch64"].each do |uname_m|
          stub_uname_m_to_return [uname_m, "", success_status]

          expect(subject.detect_cpu_type).to eq(:arm), "Expected #{uname_m} to get detected as :arm"
        end
      end
    end
  end
end
