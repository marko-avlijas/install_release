require 'settings'

describe Settings do
  it "is a singleton" do
    expect(Settings.instance).to equal(Settings.instance)
  end

  it "#set_defaults" do
    Settings.instance.set_defaults

    expect(Settings.instance.preferred_download_tool).to eq(:curl)
    expect(Settings.instance.download_dir).to eq("$HOME/src/releases/")
    expect(Settings.instance.supported_oses).to match_array([:linux])
    expect(Settings.instance.supported_package_managers).to match_array(["dpkg"])

    Settings.instance.clear
  end

  it "#clear" do
    Settings.instance.set_defaults
    Settings.instance.clear

    expect(Settings.instance.preferred_download_tool).to be nil
    expect(Settings.instance.download_dir).to be nil
    expect(Settings.instance.supported_oses).to be nil
    expect(Settings.instance.supported_package_managers).to be nil
  end
end

