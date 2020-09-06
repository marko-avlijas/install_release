require 'release'
require 'vcr_helper'

describe Release do
  describe "#github_url" do
    it "gives correct url for tag 'latest' and :latest" do
      release = Release.new(repo: "sharkdp/fd", tag: 'latest')
      expect(release.github_url).to eq("https://api.github.com/repos/sharkdp/fd/releases/latest")
    end

    it "gives correct url for tag 'v8.1.1'" do
      release = Release.new(repo: "sharkdp/fd", tag: 'v8.1.1')
      expect(release.github_url).to eq("https://api.github.com/repos/sharkdp/fd/releases/tags/v8.1.1")
    end
  end

  describe "#get_info" do
    let(:repo) { "BurntSushi/ripgrep" }
    let(:tag) {  "12.1.1" }

    it "raises Release::NotFoundError if repo doesn't exist" do
      release = Release.new(repo: "marko-avlijas/no_such_repo", tag: "latest")

      VCR.use_cassette("marko-avlijas@no_such_repo") do
        expect { release.get_info }.to raise_error Release::NotFoundError
      end
    end

    it "raises Release::NotFoundError if tag doesn't exist" do
      release = Release.new repo: repo, tag: "v123456789.12345.6322" 

      VCR.use_cassette("ripgrep@v123456789.12345.6322") do
        expect { release.get_info }.to raise_error Release::NotFoundError
      end
    end

    it "downloads assets for specific repo and tag" do
      release = Release.new repo: repo, tag: tag

      VCR.use_cassette("ripgrep@12.1.1") do
        release.get_info
      end

      asset_names = release.assets.map { |asset| asset.name }
      expect(asset_names).to contain_exactly(
        "ripgrep-12.1.1-arm-unknown-linux-gnueabihf.tar.gz",
        "ripgrep-12.1.1-i686-pc-windows-msvc.zip",
        "ripgrep-12.1.1-x86_64-apple-darwin.tar.gz",
        "ripgrep-12.1.1-x86_64-pc-windows-gnu.zip",
        "ripgrep-12.1.1-x86_64-pc-windows-msvc.zip",
        "ripgrep-12.1.1-x86_64-unknown-linux-musl.tar.gz",
        "ripgrep_12.1.1_amd64.deb"
      )

      asset_download_urls = release.assets.map { |asset| asset.download_url }
      expect(asset_download_urls).to contain_exactly(
        "https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-arm-unknown-linux-gnueabihf.tar.gz",
        "https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-i686-pc-windows-msvc.zip",
        "https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-x86_64-apple-darwin.tar.gz",
        "https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-x86_64-pc-windows-gnu.zip",
        "https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-x86_64-pc-windows-msvc.zip",
        "https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-x86_64-unknown-linux-musl.tar.gz",
        "https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb"
      )
    end

    it "follows redirect when tag is 'latest'" do
      release = Release.new repo: repo, tag: "latest"

      VCR.use_cassette("ripgrep@latest") do
        release.get_info
      end

      # I don't know what latest release will be in figure so just verify something that likely won't change
      expect(release.raw_data["url"]).to start_with("https://api.github.com/repos/BurntSushi/ripgrep/releases/")
    end
  end
end
