require_relative '../release'
require_relative '../asset'

# Chooses asset to install from list of assets in a release
# based on user's package managers, os and cpu architecture.
#
# Usage example:
#
# release = Release.new repo: 'sharkdp/fd', tag: 'latest'
# release.get_info
# asset_selector = SelectAsset.new(cpu: :x86_64, os: :linux,
#                                    package_managers: ["apt", "dpkg"], release: release)
# asset_selector.call
# puts asset_selector.suitable_assets => [asset1, asset 2]
# puts asset_selector.selected_asset => [asset1]
#
class SelectAsset
  # extend Callable - doesn't work well with named params
  class << self
    def call(cpu:, os:, package_managers:, release:)
      new(cpu: cpu, os: os, package_managers: package_managers, release: release).call
    end
  end

  attr_reader :cpu, :os, :package_managers, :release
  attr_reader :suitable_assets, :selection_strategy
  attr_reader :selection_made_at_step

  # Params are user's cpu_type, os and package_managers,
  # and release that contains assets we can choose from.
  # package_managers must be an array
  def initialize(cpu:, os:, package_managers:, release:)
    @cpu = cpu
    @os = os
    @package_managers = package_managers ? package_managers.map(&:to_s) : []
    @release = release
  end

  # Selects asset for installation.
  #
  # SELECTION STRATEGY is to choose first one of the list:
  #
  # 1. choose package manager version for my cpu
  # 2. choose package manager version for unknown cpu
  # 3. choose normal version for my os and cpu
  # 4. choose normal version for my os and unknown_cpu
  # 5. choose normal version for unknown os and my cpu, ONLY if it's only 1 such version
  #
  # Normal version means not for any package manager.
  # Now we are down to not knowing the os or cpu.
  #
  # 6. choose normal version with unknown cpu and unknown os, ONLY if it's only 1 such version
  # 7. otherwise can't decide
  #
  # If user doesn't have recognized package manager then steps 1 and 2 are skipped.
  # Rest of strategy is explained in selected_asset function.
  def call
    unless package_managers.empty?
      # 1. choose package manager version for user's cpu
      @suitable_assets = release.select_assets(cpu: cpu, os: os, package_managers: package_managers)
      @selection_made_at_step = 0
      return self unless @suitable_assets.empty?

      # 2. choose package manager version for unknown cpu
      @suitable_assets = release.select_assets(cpu: :unknown_cpu, os: os,
                                               package_managers: package_managers)
      @selection_made_at_step = 1
      return self unless @suitable_assets.empty?
    end

    # 3. choose normal version for user's os and cpu
    @suitable_assets = release.select_assets(cpu: cpu, os: os, package_managers: [:none])
    @selection_made_at_step = 2
    return self unless @suitable_assets.empty?

    # 4. choose normal version for user's os and :unknown cpu
    @suitable_assets = release.select_assets(cpu: :unknown_cpu, os: os, package_managers: [:none])
    @selection_made_at_step = 3
    return self unless @suitable_assets.empty?

    # 5. choose normal version for unknown os and user's cpu
    @suitable_assets = release.select_assets(cpu: cpu, os: :unknown_os, package_managers: [:none])
    @selection_made_at_step = 4
    return self unless @suitable_assets.empty?

    # 6. choose normal version with unknown cpu and unknown os
    @suitable_assets = release.select_assets(cpu: :unknown_cpu, os: :unknown_os,
                                             package_managers: [:none])
    @selection_made_at_step = 5
    return self unless @suitable_assets.empty?

    # 7. otherwise can't decide
    @selection_made_at_step = 6

    self
  end

  # For steps 1-4 of SELECTION STRATEGY we know that for every suitable asset
  # os matches and cpu type either matches or is unknown. That means we can be
  # pretty sure we can install any of the suitable assets.
  # We are going to choose first in the list.
  #
  # For steps 5 and 6 we don't know the os so we have no idea what the assets are about.
  # It can be anything so we are going to choose an asset only if there is only one asset.
  #
  # To be more exact only one asset that is not disqulified by mentioning wrong cpu,
  # wrong os or is for package manager that is not available on users system.
  def selected_asset
    if @selection_made_at_step < 4 || @suitable_assets.count == 1
        suitable_assets.first
    else
      nil
    end
  end

  def success?
    !selected_asset.nil?
  end

  def report
    base = <<~TEXT
      Found assets:
        #{release.assets.map(&:name).join("\n  ")}

      Selecting release for:
        Cpu type: #{cpu}
        Operating system: #{os.to_s.capitalize}
        Available package managers: #{package_managers.join(", ")}

      Asset selecting strategy:
        1. choose package manager version for user's cpu
        2. choose package manager version for unknown cpu
        3. choose non package manager version for user's os and cpu
        4. choose normal version for user's os and unknown cpu
        5. choose normal version for unknown os and user's cpu, only if it's only one such version
        6. choose normal version with unknown cpu and unknown os, only if it's only one such version
        7. otherwise can't decide

      Strategy reached step #{selection_made_at_step+1}.

    TEXT

    if success?
      explanation = <<~TEXT
        Selected asset:
        #{selected_asset.to_s}

      TEXT

      if suitable_assets.count > 1
        explanation += <<~TEXT
          Selected first from following equally suitable assets:
            #{suitable_assets.map(&:name).join("\n  ")}

        TEXT
      else
      end
    else
      if selection_made_at_step == 6
        explanation = "Could not make a choise because there was no suitable versions for your system."
      else
        explanation = <<~TEXT
          Found potentially suitable assets:
            #{suitable_assets.map(&:name).join("\n  ")}
            
          Because their operating system is not detected and I have no idea how they are different,
          I decided to rather fail than install a wrong one.
        TEXT
      end
      explanation += <<~TEXT
        FAILED to select a suitable asset.
      TEXT
    end
              
    base + explanation
  end
end
