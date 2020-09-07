require 'asset'

describe Asset do

  let(:json) do
    { "url"=>"https://api.github.com/repos/sharkdp/fd/releases/assets/21037481", "id"=>21037481, "node_id"=>"MDEyOlJlbGVhc2VBc3NldDIxMDM3NDgx", "name"=>"fd-musl_8.1.1_amd64.deb", "label"=>"", "uploader"=>{"login"=>"sharkdp", "id"=>4209276, "node_id"=>"MDQ6VXNlcjQyMDkyNzY=", "avatar_url"=>"https://avatars2.githubusercontent.com/u/4209276?v=4", "gravatar_id"=>"", "url"=>"https://api.github.com/users/sharkdp", "html_url"=>"https://github.com/sharkdp", "followers_url"=>"https://api.github.com/users/sharkdp/followers", "following_url"=>"https://api.github.com/users/sharkdp/following{/other_user}", "gists_url"=>"https://api.github.com/users/sharkdp/gists{/gist_id}", "starred_url"=>"https://api.github.com/users/sharkdp/starred{/owner}{/repo}", "subscriptions_url"=>"https://api.github.com/users/sharkdp/subscriptions", "organizations_url"=>"https://api.github.com/users/sharkdp/orgs", "repos_url"=>"https://api.github.com/users/sharkdp/repos", "events_url"=>"https://api.github.com/users/sharkdp/events{/privacy}", "received_events_url"=>"https://api.github.com/users/sharkdp/received_events", "type"=>"User", "site_admin"=>false}, "content_type"=>"application/x-debian-package", "state"=>"uploaded", "size"=>754700, "download_count"=>1706, "created_at"=>"2020-05-25T14:12:56Z", "updated_at"=>"2020-05-25T14:12:56Z", "browser_download_url"=>"https://github.com/sharkdp/fd/releases/download/v8.1.1/fd-musl_8.1.1_amd64.deb"}
  end

  describe "#name" do
    it "can be set from raw_data or directly in initializer" do
      # from name
      expect(Asset.new(name: "name").name).to eq("name")

      # from raw_data
      expect(Asset.new(raw_data: json).name).to eq("fd-musl_8.1.1_amd64.deb")

      # both
      expect(Asset.new(raw_data: json, name: "name").name).to eq("name")
    end
  end

  describe "#download_url" do
    it "can be set from raw_data or directly in initializer" do
      # from name
      expect(Asset.new(download_url: "download_url").download_url).to eq("download_url")

      # from raw_data
      expect(Asset.new(raw_data: json).download_url).to eq("https://github.com/sharkdp/fd/releases/download/v8.1.1/fd-musl_8.1.1_amd64.deb")

      # both
      expect(Asset.new(raw_data: json,download_url: "download_url").download_url).to eq("download_url")
    end
  end

  describe "#cpu_type" do
    let(:arm_asset)         { Asset.new(name: "fd-musl_8.1.1_armhf.deb") }
    let(:i386_asset)        { Asset.new(name: "fd_8.1.1_i386.deb") }
    let(:i686_asset)        { Asset.new(name: "fd-v8.1.1-i686-unknown-linux-gnu.tar.gz") }
    let(:amd64_asset)       { Asset.new(name: "fd_8.1.1_amd64.deb") }
    let(:x64_asset)         { Asset.new(name: "fd-v8.1.1-x64-unknown-linux-musl.tar.gz") }
    let(:x86_64_asset)      { Asset.new(name: "fd-v8.1.1-x86_64-unknown-linux-musl.tar.gz") }
    let(:x86_dash_64_asset) { Asset.new(name: "fd-v8.1.1-x86-64-unknown-linux-musl.tar.gz") }
    let(:unknown_cpu_asset) { Asset.new(name: "fd-v8.1.1-unknown-linux-musl.tar.gz") }

    it "detects i686 cpu_type" do
      expect(i386_asset.cpu_type).to eq(:i686)
      expect(i686_asset.cpu_type).to eq(:i686)
    end

    it "detects x86_64 cpu_type" do
      expect(amd64_asset.cpu_type).to eq(:x86_64)
      expect(x64_asset.cpu_type).to eq(:x86_64)
      expect(x86_64_asset.cpu_type).to eq(:x86_64)
      expect(x86_dash_64_asset.cpu_type).to eq(:x86_64)
    end

    it "detects arm cpu_type" do
      expect(arm_asset.cpu_type).to eq(:arm)
    end

    it "otherwise returns :unknown_cpu" do
      expect(unknown_cpu_asset.cpu_type).to eq(:unknown_cpu)
    end

    it "detects cpu_type for all assets in 'sharkdp/fd' repo" do
      names_cpu_types = {
        "fd-musl_8.1.1_amd64.deb" => :x86_64,
        "fd-musl_8.1.1_armhf.deb" => :arm,
        "fd-musl_8.1.1_i386.deb" => :i686,
        "fd-v8.1.1-arm-unknown-linux-gnueabihf.tar.gz" => :arm,
        "fd-v8.1.1-arm-unknown-linux-musleabihf.tar.gz" => :arm,
        "fd-v8.1.1-i686-pc-windows-gnu.zip" => :i686,
        "fd-v8.1.1-i686-pc-windows-msvc.zip" => :i686,
        "fd-v8.1.1-i686-unknown-linux-gnu.tar.gz" => :i686,
        "fd-v8.1.1-i686-unknown-linux-musl.tar.gz" => :i686,
        "fd-v8.1.1-x86_64-apple-darwin.tar.gz" => :x86_64,
        "fd-v8.1.1-x86_64-pc-windows-gnu.zip" => :x86_64,
        "fd-v8.1.1-x86_64-pc-windows-msvc.zip" => :x86_64,
        "fd-v8.1.1-x86_64-unknown-linux-gnu.tar.gz" => :x86_64,
        "fd-v8.1.1-x86_64-unknown-linux-musl.tar.gz" => :x86_64,
        "fd_8.1.1_amd64.deb" => :x86_64,
        "fd_8.1.1_armhf.deb" => :arm,
        "fd_8.1.1_i386.deb" => :i686
      }

      aggregate_failures do
        names_cpu_types.each do |name, cpu_type| 
          asset = Asset.new(name: name)
          actual_cpu = asset.cpu_type
          expect(actual_cpu).to eq(cpu_type), "Expected #{actual_cpu} to be #{cpu_type} for #{name}"
        end
      end
    end
  end

  describe "#os" do
    let(:deb_asset) { Asset.new(name: "fd-musl_8.1.1_amd64.deb") }
    let(:unknown_linux_gnu_asset) { Asset.new(name: "fd-v8.1.1-i686-unknown-linux-gnu.tar.gz") }
    let(:unknown_linux_musl_asset) { Asset.new(name: "fd-v8.1.1-i686-unknown-linux-musl.tar.gz") }
    let(:windows_asset) { Asset.new(name: "fd-v8.1.1-i686-pc-windows-gnu.zip") }
    let(:apple_asset) { Asset.new(name: "fd-v8.1.1-x86_64-apple-darwin.tar.gz") }

    it "detects windows" do
      expect(windows_asset.os).to eq(:windows)
    end

    it "detects darwin" do
      expect(apple_asset.os).to eq(:darwin)
    end

    it "detects unknown linux" do
      expect(unknown_linux_gnu_asset.os).to eq(:linux)
    end

    it "detects .deb as linux" do
      expect(deb_asset.os).to eq(:linux)
    end
  end

  describe "#package_manager" do
    let(:deb_asset) { Asset.new(name: "fd-musl_8.1.1_amd64.deb") }
    let(:unknown_linux_gnu_asset) { Asset.new(name: "fd-v8.1.1-i686-unknown-linux-gnu.tar.gz") }
    let(:unknown_linux_musl_asset) { Asset.new(name: "fd-v8.1.1-i686-unknown-linux-musl.tar.gz") }
    let(:windows_asset) { Asset.new(name: "fd-v8.1.1-i686-pc-windows-gnu.zip") }
    let(:apple_asset) { Asset.new(name: "fd-v8.1.1-x86_64-apple-darwin.tar.gz") }

    context "windows asset" do
      it "package manager is nil" do
      expect(windows_asset.package_manager).to be nil
      end
    end

    context "apple_asset asset" do
      it "package_manager is nil" do
        expect(apple_asset.package_manager).to be nil
      end
    end

    context "unknown linux asset" do
      it "package_manager is nil" do
        expect(unknown_linux_gnu_asset.package_manager).to be nil
      end
    end

    context ".deb asset" do
      it "package_manager is 'dpkg'" do
        expect(deb_asset.package_manager).to eq('dpkg')
      end
    end
  end
end

