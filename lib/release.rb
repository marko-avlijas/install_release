require "httparty"

# Represents a version of application. It contains one or more assets.
# Each asset is specific to certain architecture and os and maybe even distribution.
class Release
  class NotFoundError < StandardError; end

  attr_reader :repo, :tag, :assets, :raw_data

  def initialize(repo: nil, tag: nil)
    @repo = repo
    @tag = tag
    @assets = []
  end

  def get_info
    response = HTTParty.get github_url
    raise NotFoundError if response.code == 404

    @raw_data = JSON.parse(response.body)
    @assets = @raw_data["assets"].map { |asset_json| Asset.new(raw_data: asset_json) }
  end

  def github_url
    base_url = "https://api.github.com/repos/#{repo}/releases"
    suffix = (tag.to_s == "latest") ? "latest" : "tags/#{tag}"

    "#{base_url}/#{suffix}"
  end
end

