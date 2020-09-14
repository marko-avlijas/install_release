require 'service/download_asset'
require 'vcr_helper'

describe DownloadAsset do
  let(:download_dir) { File.expand_path("../../downloads", __dir__) } # FIX THIS TO BE IN SOME FOLDER
  let(:download_tool) { "curl" }
  let(:asset) do
    Asset.new(name: "fd-musl_8.1.1_amd64.deb",
              download_url: 'https://github.com/sharkdp/fd/releases/download/v8.1.1/fd-musl_8.1.1_amd64.deb')
  end
  subject { DownloadAsset.new(asset: asset, download_dir: download_dir, download_tool: download_tool) }

  it "#dest_path" do
    expect(subject.dest_path).to eq("#{download_dir}/fd-musl_8.1.1_amd64.deb")
  end

  # ====================================================
  # TODO: by default should not skip download
  # if file exists and is size it should be
  # ====================================================
  describe "#call" do
    it "when it can't create download_dir" do
      expect(FileUtils).to receive(:mkdir_p).with(download_dir).and_raise(Errno::EACCES)
      expect(subject).not_to receive(:system)

      status = subject.call
      expect(status.success?).to be false
      expect(status.error_message).to eq("Permission denied! Could not create #{download_dir}")
    end

    it "download tool returns non zero exit code" do
      expect(FileUtils).to receive(:mkdir_p).with(download_dir)
      expect(subject).to receive(:system).with(/curl/).and_return(false)

      status = subject.call
      expect(status.success?).to be false
      expect(status.error_message).to eq("FAILED to download #{asset.download_url.inspect}")
    end

    it "download tool command fails" do
      expect(FileUtils).to receive(:mkdir_p).with(download_dir)
      expect(subject).to receive(:system).with(/curl/).and_return(nil)

      status = subject.call
      expect(status.success?).to be false
      expect(status.error_message).to eq("FAILED to download #{asset.download_url.inspect}")
    end

    it "downloads asset using curl", slow: true do
      puts "Downloading to: #{download_dir}"
      @status = DownloadAsset.call(asset: asset, download_dir: download_dir, download_tool: "curl")

      expect(@status.success?).to be true
      expect(File.exist?(@status.dest_path)).to be true
    end

    it "downloads asset using wget", slow: true do
      @status = DownloadAsset.call(asset: asset, download_dir: download_dir, download_tool: "wget")

      expect(@status.success?).to be true
      expect(File.exist?(@status.dest_path)).to be true
    end
  end
end
