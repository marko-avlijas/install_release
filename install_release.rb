#! /usr/bin/env ruby

require_relative "lib/release"
require_relative "lib/installer"
require_relative "lib/options"
require_relative "lib/system_helper"

require_relative "lib/service/detect_system"
require_relative "lib/service/select_asset"
require_relative "lib/service/download_asset"

Settings.instance.set_defaults
options = Options.parse(ARGV)

installer = Installer.new(options)
status_code = installer.install
exit status_code
