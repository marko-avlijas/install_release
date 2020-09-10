require 'options'

describe Options do
  describe ".parse" do
    it "aborts if --git is not specified" do
      expect { Options.parse [] }.to output(/You must specify a git repo/).to_stderr
                                 .and raise_error(SystemExit)
    end

    it "recognizes --git REPO and sets tag to :latest_release" do
      expect(Options.parse ["--git", "sharkdp/fd"] ).to eq(git: 'sharkdp/fd', tag: :latest)
    end

    it "recognizes --tag TAG" do
      options = ["--git", "sharkdp/fd", "--tag", "1.1.1"]
      expect(Options.parse options).to eq(git: 'sharkdp/fd', tag: "1.1.1")
    end

    it "recognizes --help" do
      expect { Options.parse(["--help"]) }.to output(/Usage/).to_stdout
                                          .and raise_error(SystemExit)
    end

    it "recognizes -h" do
      expect { Options.parse(["-h"]) }.to output(/Usage/).to_stdout
                                      .and raise_error(SystemExit)
    end
  end
end

