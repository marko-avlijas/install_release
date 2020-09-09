require 'optparse'

# Command line options
class Options

  attr_reader :git # slug like 'sharkdp/fd' which is short for https://github.com/sharkdp/fd/
  attr_reader :force, :binary
  # Return a structure describing the options.
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.git = ""
    options.force = false
    options.binary = ""
    options.tag = :latest_release
    options.target = "x86_64-unknown-linux-gnu"
    options.extension = "tar.gz"
    options.destination = "#{ENV["HOME"]}/bin"

    opt_parser = OptionParser.new do |opts|
      opts.banner=<<~TEXT
        Install a binary release of a project hosted on GitHub

        Usage:
            install.rb --git SLUG [options]
      TEXT

      opts.separator ""
      opts.separator "Mandatory options:"

      # mandatory argument
      opts.on("--git SLUG",
              "Get the binary from 'https://github/SLUG'") do |git|
        options.git = git
      end

      opts.separator ""
      opts.separator "Other options:"

      opts.on("--binary NAME",
              "Name of the binary to install (default <repository name>)") do |binary|
        options.binary = binary 
      end

      opts.on("--tag TAG",
              "Tag (version) of the crate to install (default <latest release>)") do |tag|
        options.tag = tag 
      end

      opts.on("--target TARGET",
              "Install the release compiled for TARGET (default x86_64-unknown-linux-gnu)") do |target|
        options.target = target 
      end

      opts.on("--extension EXTENSION",
              "download version that ends with EXTENSION (default tar.gz)") do |extension|
        options.extension = extension 
      end

      opts.on("--dest LOCATION",
              "Where to install the binary (default ~/bin)") do |dest|
        options.dest = dest 
      end

      opts.on("-f", "--force",
              "Force overwriting an existing binary") do |force|
        options.force = true
      end

      # No argument, shows at tail.  This will print usage and options summary.
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)

    if options.git.empty?
      puts "You must specify a git repository using '--git'."
      puts "Example: install_from_release.rb --git 'sharkdp/fd'"
      exit
    end

    if options.binary.empty?
      options.binary = options.git.split("/").last
    end

    options
  end

  def resolve_download_url(options)
    if options.tag == :latest_release
      latest_release_url = "https://github.com/" + File.join(options.git, "releases", "latest")

      # curl returns <html><body>You are being <a href="https://github.com/sharkdp/fd/releases/tag/v8.1.1">redirected</a>.</body></html>
      redirect_str = `curl -s #{latest_release_url}`

      # extract href
      href_regex = /<a\s*href="(?<href>.*)">\s*redirected<\/a>/
      matches = redirect_str.match href_regex
      abort "Expected github to respond with redirect for url:\n#{latest_release_url}.\nGot: #{redirect_str}" if matches.nil?
      href = matches[:href]

      tag_regex = /releases\/tag\/(?<tag>.*)$/
      matches = href.match tag_regex
      abort "Expected github to redirect to link which ends with releases/tag/(tag)\nGot: #{href}" if matches.nil?
      options.tag = matches[:tag]
    end

    release_name = "#{options.binary}-#{options.tag}-#{options.target}.#{options.extension}"
    options.download_url = "https://github.com/" + File.join(options.git, "releases", "download", options.tag, release_name)
  end

  def present_options(options)
    puts "git: #{options.git}"
    puts "binary: #{options.binary}"
    puts "tag (version): #{options.tag}"
    puts "overwrite if exists: #{options.force}"
    puts "download url: #{options.download_url}"
    puts "destination: #{options.destination}"
    puts
  end
end
