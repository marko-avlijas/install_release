require 'settings'

describe Settings do
  it "is a singleton" do
    expect(Settings.instance).to equal(Settings.instance)
  end

  it "#set_defaults" do
    Settings.instance.set_defaults

    expect(Settings.instance.download_tool).to eq(:curl)
    expect(Settings.instance.download_dir).to eq("$HOME/src/releases/")
  end
end

