require 'settings'
require 'installer'

describe Installer do
  subject { described_class.new(repo: "sharkdp/fd", tag: "latest") }
end

