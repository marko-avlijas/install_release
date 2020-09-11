require 'release'
require 'vcr_helper'

describe Release do
  it "#list_releases_url" do
    release = Release.new(repo: "vim/vim")
    expect(release.list_releases_url).to eq("https://api.github.com/repos/vim/vim/releases")
  end

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

    it "raises Release::RepoNotFoundError if repo doesn't exist" do
      release = Release.new(repo: "marko-avlijas/no_such_repo", tag: "latest")

      VCR.use_cassette("marko-avlijas_no_such_repo") do
        expect { release.get_info }.to raise_error Release::RepoNotFoundError
      end
    end

    it "raises Release::TagNotFoundError if tag doesn't exist" do
      release = Release.new repo: repo, tag: "v123456789.12345.6322" 

      VCR.use_cassette("ripgrep_v123456789.12345.6322") do
        expect { release.get_info }.to raise_error Release::TagNotFoundError
      end
    end

    it "raises Release::RepoHasNoReleasesError if repo doesn't have releases" do
      release = Release.new(repo: "marko-avlijas/dotfiles", tag: "latest")

      VCR.use_cassette("marko-avlijas_dotfiles") do
        expect { release.get_info }.to raise_error Release::RepoHasNoReleasesError
      end
    end

    it "downloads assets for specific repo and tag" do
      release = Release.new repo: repo, tag: tag

      VCR.use_cassette("ripgrep_12.1.1") do
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

      VCR.use_cassette("ripgrep_latest") do
        release.get_info
      end

      # I don't know what latest release will be in figure so just verify something that likely won't change
      expect(release.raw_data["url"]).to start_with("https://api.github.com/repos/BurntSushi/ripgrep/releases/")
      expect(release.raw_data["tag_name"]).to be >= "12.1.1"
    end
  end

  describe "#select_assets" do
    context "selecting by cpu_type" do
      let(:arm_asset)         { Asset.new(name: "bat-arm") }
      let(:i686_asset)        { Asset.new(name: "bat-i686") }
      let(:amd64_asset)       { Asset.new(name: "bat-amd64") }
      let(:x86_64_asset)      { Asset.new(name: "bat-x86_64") }
      let(:unknown_cpu_asset) { Asset.new(name: "bat-unknown") }

      specify do
        all_assets = amd64_asset, x86_64_asset, i686_asset, arm_asset, unknown_cpu_asset
        subject.assets.push(*all_assets)

        expect(subject.select_assets(cpu: :any)).to contain_exactly(*all_assets)
        expect(subject.select_assets(cpu: :arm)).to contain_exactly(arm_asset)
        expect(subject.select_assets(cpu: :i686)).to contain_exactly(i686_asset)
        expect(subject.select_assets(cpu: :x86_64)).to contain_exactly(amd64_asset, x86_64_asset)
        expect(subject.select_assets(cpu: :unknown_cpu)).to contain_exactly(unknown_cpu_asset)

        # it does not change assets collection
        expect(subject.assets).to contain_exactly(*all_assets)
      end
    end

    context "selecting by os" do
      let(:windows_asset)     { Asset.new(name: "bat-windows") }
      let(:apple_asset)       { Asset.new(name: "bat-apple") }
      let(:darwin_asset)      { Asset.new(name: "bat_darwin") }
      let(:linux_asset)       { Asset.new(name: "bat_linux") }
      let(:debian_asset)      { Asset.new(name: "bat.deb") }
      let(:unknown_os_asset)  { Asset.new(name: "bat") }

      specify do
        all_assets = [windows_asset, apple_asset, darwin_asset,
                      linux_asset, debian_asset, unknown_os_asset]
        subject.assets.push(*all_assets)

        expect(subject.select_assets(os: :any)).to contain_exactly(*all_assets)
        expect(subject.select_assets(os: :windows)).to contain_exactly(windows_asset)
        expect(subject.select_assets(os: :darwin)).to contain_exactly(apple_asset, darwin_asset)
        expect(subject.select_assets(os: :linux)).to contain_exactly(linux_asset, debian_asset)
        expect(subject.select_assets(os: :unknown_os)).to contain_exactly(unknown_os_asset)

        # it does not change assets collection
        expect(subject.assets).to contain_exactly(*all_assets)
      end
    end

    context "selecting by package_managers" do
      let(:linux_asset)       { Asset.new(name: "bat_linux.tar.gz") }
      let(:debian_asset)      { Asset.new(name: "bat.deb") }

      specify do
        all_assets = [linux_asset, debian_asset]
        subject.assets.push(*all_assets)

        expect(subject.select_assets(package_managers: :any)).to contain_exactly(*all_assets)
        expect(subject.select_assets(package_managers: [:none])).to contain_exactly(linux_asset)
        expect(subject.select_assets(package_managers: ["dpkg"])).to contain_exactly(debian_asset)
        expect(subject.select_assets(package_managers: ["dpkg", :none])).to contain_exactly(*all_assets)
      end
    end
  end
end
