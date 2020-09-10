require 'service/select_asset'

describe SelectAsset do
  let(:release) { Release.new }

  describe "#call" do
    # they should be selected in this order
    let(:package_manager_my_cpu_asset) { Asset.new(name: "fd-amd64.deb", download_url: "") }
    let(:package_manager_unknown_cpu_asset) { Asset.new(name: "fd.deb", download_url: "") }
    let(:my_os_and_cpu_asset) { Asset.new(name: "fd-unknown-linux-amd64.tar.gz", download_url: "") }
    let(:my_os_and_uknown_cpu_asset) { Asset.new(name: "fd-unknown-linux.tar.gz", download_url: "") }
    let(:unknown_os_and_my_cpu_asset) { Asset.new(name: "fd-amd64.tar.gz", download_url: "") }

    let(:all_ok_assets) do
      [package_manager_my_cpu_asset, package_manager_unknown_cpu_asset,
       my_os_and_cpu_asset, my_os_and_uknown_cpu_asset, unknown_os_and_my_cpu_asset]
    end

    # ok if only asset
    let(:everything_unknown_asset) { Asset.new(name: "fd.zip", download_url: "") }

    # these should never be selected even if it's the only release

    # TODO: support other package managers
    # let(:other_package_manager_my_cpu_asset) { Asset.new(name: "fd-amd64.rpm") }
    # let(:other_package_manager_unknown_cpu_asset) { Asset.new(name: "fd.rpm") }
    let(:package_manager_other_cpu_asset) { Asset.new(name: "fd-arm.deb", download_url: "") }
    let(:my_os_and_other_cpu_asset) { Asset.new(name: "fd-unknown-linux-arm.tar.gz", download_url: "") }
    let(:other_os_and_my_cpu_asset) { Asset.new(name: "fd-darwin-amd64.tar.gz", download_url: "") }
    let(:other_os_and_unknown_cpu_asset) { Asset.new(name: "fd-darwin.tar.gz", download_url: "") }
    let(:other_os_and_other_cpu_asset) { Asset.new(name: "fd-darwin-arm.tar.gz", download_url: "") }

    let(:all_never_ok_assets) do
      [package_manager_other_cpu_asset, my_os_and_other_cpu_asset,
       other_os_and_my_cpu_asset, other_os_and_unknown_cpu_asset,
       other_os_and_other_cpu_asset,
      ]
    end

    # add all assets to release
    # let tests remove ones they do not need
    before(:each) do
      release.assets.push(*all_never_ok_assets)
      release.assets.push(*all_ok_assets)
      release.assets.push(everything_unknown_asset)
    end

    # Get diff on names, not entire objects
    def expect_suitable_assets(expected_assets)
      expected_names = expected_assets.map(&:name)
      actual_names = @result.suitable_assets.map(&:name)

      expect(actual_names).to match_array(expected_names)
    end

    # All parameters represent expectations on result.
    # This function enforces all excpectations.
    #
    # Param selected_asset must be one Asset and
    # if it can be any of two values, then use param selected_asset_either_or
    def expect_result(suitable_assets:, selection_made_at_step:, selected_asset:, success:)
      expect_suitable_assets(suitable_assets)
      expect(@result.selection_made_at_step).to eq selection_made_at_step
      expect(@result.selected_asset).to be selected_asset
      expect(@result.success?).to be success

      if success
        expect(@result.report).to match(/#{selected_asset}/)
      else
        expect(@result.report).to match(/FAILED/)
      end
    end

    def call
      described_class.call(cpu: :x86_64, os: :linux,
                           package_managers: ["apt", "apt-get", "dpkg"],
                           release: release)
    end

    it "1. chooses package manager version for my cpu" do
      # when there  is only one choice
      @result = call
      expect_result suitable_assets: [package_manager_my_cpu_asset],
                    selection_made_at_step: 0,
                    selected_asset: package_manager_my_cpu_asset,
                    success: true

      # when there are two choices
      package_manager_my_cpu_asset2 = Asset.new(name: "fd-whatever-amd64.deb")
      release.assets.push(package_manager_my_cpu_asset2)
      @result = call
      expect_result suitable_assets: [package_manager_my_cpu_asset,
                                       package_manager_my_cpu_asset2],
                     selection_made_at_step: 0,
                     selected_asset: package_manager_my_cpu_asset,
                     success: true

      # when user has no package manager choose normal version skip to step 3
      @result = described_class.call(cpu: :x86_64, os: :linux,
                                     package_managers: [],
                                     release: release)
      expect_result suitable_assets: [my_os_and_cpu_asset],
                     selection_made_at_step: 2,
                     selected_asset: my_os_and_cpu_asset,
                     success: true
    end

    it "2. chooses package manager version for :unknown_cpu" do
      # add all assets except step 1 assets
      release.assets.delete(package_manager_my_cpu_asset)

      # when there  is only one choice
      @result = call
      expect_result suitable_assets: [package_manager_unknown_cpu_asset],
                     selection_made_at_step: 1,
                     selected_asset: package_manager_unknown_cpu_asset,
                     success: true

      # when there are two choices
      package_manager_unknown_cpu_asset2 = Asset.new(name: "fd-whatever.deb")
      release.assets.push(package_manager_unknown_cpu_asset2)
      @result = call
      expect_result suitable_assets: [package_manager_unknown_cpu_asset,
                                       package_manager_unknown_cpu_asset2],
                     selection_made_at_step: 1,
                     selected_asset: package_manager_unknown_cpu_asset,
                     success: true

      # when user has no package manager choose normal version skip to step 3
      @result = described_class.call(cpu: :x86_64, os: :linux,
                                     package_managers: [],
                                     release: release)
      expect_result suitable_assets: [my_os_and_cpu_asset],
                     selection_made_at_step: 2,
                     selected_asset: my_os_and_cpu_asset,
                     success: true
    end

    it "3. chooses normal version for my os and cpu" do
      # add all assets except step 1 & 2 assets
      release.assets.delete(package_manager_my_cpu_asset)
      release.assets.delete(package_manager_unknown_cpu_asset)

      # when there  is only one choice
      @result = call
      expect_result suitable_assets: [my_os_and_cpu_asset],
                     selection_made_at_step: 2,
                     selected_asset: my_os_and_cpu_asset,
                     success: true

      # when there are two choices
      my_os_and_cpu_asset2 = Asset.new(name: "fd-unknown-linux-amd64-whatever.tar.gz")
      release.assets.push(my_os_and_cpu_asset2)
      @result = call
      expect_result suitable_assets: [my_os_and_cpu_asset, my_os_and_cpu_asset2],
                     selection_made_at_step: 2,
                     selected_asset: my_os_and_cpu_asset,
                     success: true
    end

    it "4. chooses normal version for my os and unknown cpu" do
      # add all assets except step 1, 2 & 3 assets
      release.assets.delete(package_manager_my_cpu_asset)
      release.assets.delete(package_manager_unknown_cpu_asset)
      release.assets.delete(my_os_and_cpu_asset)

      # when there  is only one choice
      @result = call
      expect_result suitable_assets: [my_os_and_uknown_cpu_asset],
                     selection_made_at_step: 3,
                     selected_asset: my_os_and_uknown_cpu_asset,
                     success: true

      # when there are two choices
      my_os_and_uknown_cpu_asset2 = Asset.new(name: "fd-unknown-linux-whatever.tar.gz")
      release.assets.push(my_os_and_uknown_cpu_asset2)
      @result = call
      expect_result suitable_assets: [my_os_and_uknown_cpu_asset, my_os_and_uknown_cpu_asset2],
                     selection_made_at_step: 3,
                     selected_asset: my_os_and_uknown_cpu_asset,
                     success: true
    end

    it "5. chooses normal version for :unknown_os and my cpu" do
      # add all assets except step 1, 2, 3 & 4 assets
      release.assets.delete(package_manager_my_cpu_asset)
      release.assets.delete(package_manager_unknown_cpu_asset)
      release.assets.delete(my_os_and_cpu_asset)
      release.assets.delete(my_os_and_uknown_cpu_asset)

      # when there  is only one choice
      @result = call
      expect_result suitable_assets: [unknown_os_and_my_cpu_asset],
                     selection_made_at_step: 4,
                     selected_asset: unknown_os_and_my_cpu_asset,
                     success: true

      # when there are two choices it chooses next step
      unknown_os_and_my_cpu_asset2 = Asset.new(name: "fd-amd64-whatever.tar.gz")
      release.assets.push(unknown_os_and_my_cpu_asset2)
      @result = call
      expect_result suitable_assets: [unknown_os_and_my_cpu_asset, unknown_os_and_my_cpu_asset2],
                     selection_made_at_step: 4,
                     selected_asset: nil,
                     success: false
    end

    it "6. choose normal version with unknown cpu and unknown os" do
      # add all assets except step 1, 2, 3, 4 & 5 assets
      release.assets.clear
      release.assets.push(*all_never_ok_assets)
      release.assets.push(everything_unknown_asset)

      # when there  is only one choice
      @result = call
      expect_result suitable_assets: [everything_unknown_asset],
                     selection_made_at_step: 5,
                     selected_asset: everything_unknown_asset,
                     success: true

      # when there are two choices it chooses next step
      everything_unknown_asset2 = Asset.new(name: "fd-whatever.zip")
      release.assets.push everything_unknown_asset2
      @result = call
      expect_result suitable_assets: [everything_unknown_asset, everything_unknown_asset2],
                     selection_made_at_step: 5,
                     selected_asset: nil,
                     success: false
    end

    it "7. otherwise can't decide" do
      # add only assets with wrong os / cpu type
      release.assets.clear
      release.assets.push(*all_never_ok_assets)

      # there are no choices
      @result = call
      expect_result suitable_assets: [],
                     selection_made_at_step: 6,
                     selected_asset: nil,
                     success: false
    end
  end
end

