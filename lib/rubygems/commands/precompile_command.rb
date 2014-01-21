require "rubygems/command"

class Gem::Commands::PrecompileCommand < Gem::Command
  def initialize
    super "precompile", "Create a bundle containing the compiled artifacts for this platform", :output => Dir.pwd, :arch => false

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
      raise Gem::CommandLineError, "Please specify a gem file on the command line, e.g. #{program_name} foo-0.1.0.gem"
    end

    require "rubygems/precompiler"

    gemfiles.each do |gemfile|
      compiler = Gem::Precompiler.new(gemfile, options)
      if compiler.has_extension?
        $stderr.puts "Compiling '#{compiler.gem_name}'... "
        compiler.compile
        $stderr.puts "done."
      else
        $stderr.puts "The gem '#{compiler.gem_name}' doesn't contain a compiled extension"
      end
    end
  end
end