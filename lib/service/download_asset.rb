require_relative '../asset'

# Creates download_dir if it doesn't exist and downloads asset there.
class DownloadAsset
  class << self
    def call(**params)
      new(**params).call
    end
  end

  attr_reader :asset, :download_dir, :download_tool, :success, :error_message

  def initialize(asset:, download_dir:, download_tool:)
    @asset = asset
    @download_dir = download_dir
    @download_tool = download_tool
    @success = true
  end

  def success?
    @success
  end

  def dest_path
    File.join(download_dir, asset.name)
  end

  def call
    create_dir
    download_asset if success?

    self
  end

  private

    def create_dir
      FileUtils.mkdir_p(download_dir)
    rescue Errno::EACCES
      @success = false
      @error_message = "Permission denied! Could not create #{download_dir}"
    end

    def download_asset
      unless system(download_command)
        @success = false
        @error_message = "FAILED to download #{asset.download_url.inspect}"
      end
    end

    def download_command
      if download_tool.to_s == "curl"
        curl_command
      elsif download_tool.to_s == "wget"
        wget_command
      else
        raise "Unsupported download tool #{download_tool.inspect}"
      end
    end

    def curl_command
      dest_path = File.join(download_dir, asset.name)
      "curl -L --output '#{dest_path}' '#{asset.download_url}'"
    end

    def wget_command
      "wget --directory-prefix='#{download_dir}' '#{asset.download_url}'"
    end
end
