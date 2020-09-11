require "httparty"
require_relative "asset"

# Represents a version of application. It contains one or more assets.
# Each asset is specific to certain architecture and os and maybe even distribution.
class Release
  class RepoNotFoundError < StandardError; end
  class TagNotFoundError < StandardError; end
  class RepoHasNoReleasesError < StandardError; end

  attr_reader :repo, :tag, :assets, :raw_data

  def initialize(repo: nil, tag: nil)
    @repo = repo
    @tag = tag
    @assets = []
  end

  def get_info
    response = HTTParty.get(list_releases_url, headers: {"User-Agent" => "install_release"}) 
    raise RepoNotFoundError, "Couldn't find #{list_releases_url}" if response.code.between?(400, 499)

    releases = JSON.parse(response.body)
    raise RepoHasNoReleasesError, "Repo #{repo} has no releases." if releases.empty?

    @raw_data = if tag.to_s == "latest"
                  releases.first
                else
                  releases.select { |release| release["tag_name"] == tag }.first
                end

    raise TagNotFoundError, "Release with tag #{tag.inspect} does not exist" if @raw_data.nil?

    @assets = @raw_data["assets"].map { |asset_json| Asset.new(raw_data: asset_json) }
  end

  def list_releases_url
    "https://api.github.com/repos/#{repo}/releases"
  end

  def github_url
    base_url = "https://api.github.com/repos/#{repo}/releases"
    suffix = (tag.to_s == "latest") ? "latest" : "tags/#{tag}"

    "#{base_url}/#{suffix}"
  end

  # Selects assets that match given criteria.
  # Param package_managers must be :any or array of package managers
  # Example of valid package_managers values: :any, [:none], ["dpkg"], ["apt", "dpkg", :none]
  #
  # Example:
  #
  # release = Release.new(repo: 'sharkdp/fd', tag: 'latest')
  # release.get_info
  #
  # # select all linux 64 bit releases, regardless if it's a package or not
  # release.select_assets(cpu: :x86_64, os: :linux)
  # 
  # # select all linux 64 bit releases which are not packages like .deb or .rpm
  # release.select_assets(cpu: :x86_64, os: :linux, package_managers: :none)
  #
  # # select all linux 64 bit releases which are packages for apt, apt-get or dpkg
  # release.select_assets(cpu: :x86_64, os: :linux, package_managers: ["apt", "dpkg"])
  def select_assets(cpu: :any, os: :any, package_managers: :any)
    assets.select do |asset|
      (cpu == :any || asset.cpu_type == cpu) &&
        (os  == :any || asset.os == os) &&
        (package_managers == :any || package_managers.include?(asset.package_manager))
    end
  end
end

