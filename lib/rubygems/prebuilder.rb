require "rbconfig"
require "tmpdir"
require "rubygems/installer"
require "fileutils"
require 'rubygems/package/tar_writer'
require 'zlib'

class Gem::Prebuilder
  include Gem::UserInteraction

  # raise when there is a error
  class CompilerError < Gem::InstallError; end

  attr_reader :tmp_dir, :target_dir, :options

  def initialize(gemfile, _options = {})
    @gemfile    = gemfile
    @output_dir = _options.delete(:output)
    @options    = _options
  end

  def compile
    unpack

    # build extensions
    installer.build_extensions

    # determine build artifacts from require_paths
    dlext    = RbConfig::CONFIG["DLEXT"]
    lib_dirs = installer.spec.require_paths.join(",")

    artifacts = Dir.glob("#{target_dir}/{#{lib_dirs}}/**/*.#{dlext}")

    tar_file = File.join(tmp_dir, "output.tgz")

    # Now, write all the artifacts into a tar bundle
    Zlib::GzipWriter.open(tar_file) do |tar_file_io|
      Gem::Package::TarWriter.new(tar_file_io) do |tar_file|

        artifacts.each do |path|
          artifact_path = Pathname.new(path)

          stat = File.stat(artifact_path)
          mode = stat.mode
          size = stat.size

          File.open(artifact_path, "r") do |source|

            tar_file.add_file_simple(artifact_path.relative_path_from(Pathname.new(target_dir)).to_s, mode, size) do |dest|
              until source.eof?
                dest.write source.read(1024)
              end
            end
          end
        end
      end
    end

    output_path = if options[:arch]
      File.join(@output_dir, "/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}/#{Gem::Platform.local.to_s}")
    else
      @output_dir
    end

    output_path = File.join(output_path, "#{installer.spec.name}-#{installer.spec.version}.tgz")
    FileUtils.mkdir_p(File.dirname(output_path))
    FileUtils.mv(tar_file, output_path)
    cleanup

    rescue
      p $!.inspect
      $!.backtrace.each { |a| puts a}
      raise
  end

  private

  def info(msg)
    say msg if Gem.configuration.verbose
  end

  def debug(msg)
    say msg if Gem.configuration.really_verbose
  end

  def installer
    return @installer if @installer

    @installer = Gem::Installer.new(@gemfile, options.dup.merge(:unpack => true))

    # Hmm, gem already compiled?
    if @installer.spec.platform != Gem::Platform::RUBY
      raise CompilerError,
            "The gem file seems to be compiled already."
    end

    # Hmm, no extensions?
    if @installer.spec.extensions.empty?
      raise CompilerError,
            "There are no extensions to build on this gem file."
    end

    @installer
  end

  def tmp_dir
    @tmp_dir ||= Dir.mktmpdir
  end

  def unpack
    basename    = File.basename(@gemfile, '.gem')
    @target_dir = File.join(tmp_dir, basename)

    # unpack gem sources into target_dir
    # We need the basename to keep the unpack happy
    info "Unpacking gem: '#{basename}' in temporary directory..."
    installer.unpack(@target_dir)
  end

  def cleanup
    FileUtils.rm_rf tmp_dir
  end
end