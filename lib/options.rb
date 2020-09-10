require 'optparse'

# Command line options
class Options
  attr_reader :git # repo like 'sharkdp/fd' which is short for https://github.com/sharkdp/fd/
  attr_reader :force, :binary

  # Parses options and returns a hash describing the options.
  # Aborts with error message if required options are not given.
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = {}
    options[:tag] = :latest_release

    opt_parser = OptionParser.new do |opts|
      opts.banner=<<~TEXT
        Install a binary release of a project hosted on GitHub

        Usage:
            install_release.rb --git REPO [options]

            You can also specify tag (version) like this:
            install_release.rb --git REPO --tag TAG

            If no tag is specified then latest release will be installed.
      TEXT

      opts.separator ""
      opts.separator "Mandatory options:"

      # mandatory argument
      opts.on("--git REPO",
              "Get the binary from 'https://github.com/REPO'") do |git|
        options[:git] = git
      end

      opts.separator ""
      opts.separator "Other options:"

      opts.on("--tag TAG",
              "Tag (version) of the crate to install (default <latest release>)") do |tag|
        options[:tag] = tag 
      end

      # No argument, shows at tail.  This will print usage and options summary.
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)

    if options[:git].nil?
      abort <<~TEXT
        You must specify a git repository using '--git'.
        Run with --help to see more details.
      TEXT
    end

    options
  end
end
