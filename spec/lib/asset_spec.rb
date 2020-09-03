require 'asset'

describe Asset do

  describe "from_json(json)" do
    it "saves json as raw_data" do
      json = { "url"=>"https://api.github.com/repos/sharkdp/fd/releases/assets/21037481", "id"=>21037481, "node_id"=>"MDEyOlJlbGVhc2VBc3NldDIxMDM3NDgx", "name"=>"fd-musl_8.1.1_amd64.deb", "label"=>"", "uploader"=>{"login"=>"sharkdp", "id"=>4209276, "node_id"=>"MDQ6VXNlcjQyMDkyNzY=", "avatar_url"=>"https://avatars2.githubusercontent.com/u/4209276?v=4", "gravatar_id"=>"", "url"=>"https://api.github.com/users/sharkdp", "html_url"=>"https://github.com/sharkdp", "followers_url"=>"https://api.github.com/users/sharkdp/followers", "following_url"=>"https://api.github.com/users/sharkdp/following{/other_user}", "gists_url"=>"https://api.github.com/users/sharkdp/gists{/gist_id}", "starred_url"=>"https://api.github.com/users/sharkdp/starred{/owner}{/repo}", "subscriptions_url"=>"https://api.github.com/users/sharkdp/subscriptions", "organizations_url"=>"https://api.github.com/users/sharkdp/orgs", "repos_url"=>"https://api.github.com/users/sharkdp/repos", "events_url"=>"https://api.github.com/users/sharkdp/events{/privacy}", "received_events_url"=>"https://api.github.com/users/sharkdp/received_events", "type"=>"User", "site_admin"=>false}, "content_type"=>"application/x-debian-package", "state"=>"uploaded", "size"=>754700, "download_count"=>1706, "created_at"=>"2020-05-25T14:12:56Z", "updated_at"=>"2020-05-25T14:12:56Z", "browser_download_url"=>"https://github.com/sharkdp/fd/releases/download/v8.1.1/fd-musl_8.1.1_amd64.deb"}
      asset = Asset.from_json(json)

      expect(asset.raw_data).to eq(json)
    end

  end

  describe "#architecture" do
    let(:arm_asset) { Asset.new(name: "fd-musl_8.1.1_armhf.deb") }
    let(:i386_asset) { Asset.new(name: "fd_8.1.1_i386.deb") }
    let(:i686_asset) { Asset.new(name: "fd-v8.1.1-i686-unknown-linux-gnu.tar.gz") }
    let(:amd64_asset) { Asset.new(name: "fd_8.1.1_amd64.deb") }
    let(:x86_64_asset) { Asset.new(name: "fd-v8.1.1-x86_64-unknown-linux-musl.tar.gz") }

    it "detects i386 architecture" do
      expect(i686_asset.architecture).not_to eq(:i386)

      expect(i386_asset.architecture).to eq(:i386)
    end

    it "detects i686 architecture" do
      expect(amd64_asset.architecture).not_to eq(:i686)

      expect(i686_asset.architecture).to eq(:i686)
    end

    it "detects x86_64 architecture" do
      expect(i686_asset.architecture).not_to eq(:x86_64)

      expect(amd64_asset.architecture).to eq(:x86_64)
      expect(x86_64_asset.architecture).to eq(:x86_64)
    end

    it "detects arm architecture" do
      expect(amd64_asset.architecture).not_to eq(:arm)

      expect(arm_asset.architecture).to eq(:arm)
    end

    it "detects architecture for all assets in 'sharkdp/fd' repo" do
      names = [
        "fd-musl_8.1.1_amd64.deb",
        "fd-musl_8.1.1_armhf.deb",
        "fd-musl_8.1.1_i386.deb",
        "fd-v8.1.1-arm-unknown-linux-gnueabihf.tar.gz",
        "fd-v8.1.1-arm-unknown-linux-musleabihf.tar.gz",
        "fd-v8.1.1-i686-pc-windows-gnu.zip",
        "fd-v8.1.1-i686-pc-windows-msvc.zip",
        "fd-v8.1.1-i686-unknown-linux-gnu.tar.gz",
        "fd-v8.1.1-i686-unknown-linux-musl.tar.gz",
        "fd-v8.1.1-x86_64-apple-darwin.tar.gz",
        "fd-v8.1.1-x86_64-pc-windows-gnu.zip",
        "fd-v8.1.1-x86_64-pc-windows-msvc.zip",
        "fd-v8.1.1-x86_64-unknown-linux-gnu.tar.gz",
        "fd-v8.1.1-x86_64-unknown-linux-musl.tar.gz",
        "fd_8.1.1_amd64.deb",
        "fd_8.1.1_armhf.deb",
        "fd_8.1.1_i386.deb"
      ]
      assets = names.map { |name| Asset.new(name: name) }

      aggregate_failures do
        assets.each do |asset|
          expect(asset.architecture).not_to be_nil, "couldn't detect architecture for: #{asset.name}"
        end
      end
    end
  end
end

