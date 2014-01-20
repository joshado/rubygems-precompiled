require "rubygems/command"

class Gem::Commands::PrebuildCommand < Gem::Command
  def initialize
    super "compile", "Create a bundle containing the compiled artifacts for this platform", :output => Dir.pwd, :arch => false

    add_option('-o PATH', '--output=PATH', 'The output directory for the generated bundle. Defaults to the current directory') do |path,options|
      options[:output] = path
    end

    add_option('-a','--arch-dirs','Adds the architecture sub-folders to the output directory before writing') do |arch, options|
      options[:arch] = true
    end
  end

  def arguments
    "GEMFILE       path to the gem file to compile"
  end

  def usage
    "#{program_name} GEMFILE"
  end

  def execute
    gemfiles = options[:args]

    # no gem, no binary
    if gemfiles.empty?
      raise Gem::CommandLineError,
            "Please specify a gem file on the command line (e.g. #{program_name} foo-0.1.0.gem)"
    end

    require "rubygems/prebuilder"

    gemfiles.each do |gemfile|
      compiler = Gem::Prebuilder.new(gemfile, options)
      compiler.compile
    end
  end
end