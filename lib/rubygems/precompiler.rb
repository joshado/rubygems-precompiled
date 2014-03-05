require "rbconfig"
require "tmpdir"
require "rubygems/installer"
require "fileutils"
require 'rubygems/package/tar_writer'
require 'zlib'
require 'pathname'

class Gem::Precompiler
  include FileUtils

  def initialize(gemfile, opts = {})
    @package = Gem::Package.new(gemfile)

    # @installer = Gem::Installer.new(gemfile, opts.dup.merge(:unpack => true))
    @target_dir = opts.fetch(:output, Dir.pwd)
    @target_dir = File.join(@target_dir, arch_string) if opts.fetch(:arch, false)
    @options = opts
  end

  # Private: Extracts the gem files into the specified path
  #
  def extract_files_into(dir)
    @package.extract_files dir
  end

  # Public: Returns the name of the gem
  #
  # Returns a string
  def gem_name
    @package.spec.name
  end

  # Public: Returns the version string of the gem
  #
  # Returns a Gem::Version
  def gem_version
    @package.spec.version
  end

  # Public: Returns the relative require-paths specified by the gem
  #
  # Returns an array of strings
  def gem_require_paths
    @package.spec.require_paths
  end

  # Public: Does the gem actually have any compiled extensions?
  #
  # Returns boolean - true if the gem has a c-extension that needs building
  def has_extension?
    !@package.spec.extensions.empty?
  end

  # Private: Yield the path to a temporary directory that will get deleted when
  # the block returns
  #
  def tempdir
    temp_dir = Dir.mktmpdir
    yield temp_dir
  ensure
    rm_rf temp_dir
  end

  # Private: Return a string that uniquely keys this machines ruby version and architecture
  #
  # Returns string
  def arch_string
    "ruby-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}/#{Gem::Platform.local.to_s}"
  end

  # Public: The filename of the compiled bundle for this gem
  #
  # Returns a string
  def output_path
    File.join(*[@target_dir, "#{gem_name}-#{gem_version.to_s}.tar.gz"].compact)
  end

  # Private: Return a list fo build-products in a given directory
  #
  # Returns an array of paths
  def build_products(path)
    dlext = RbConfig::CONFIG["DLEXT"]
    lib_dirs = gem_require_paths.join(',')
    Dir.glob("#{path}/{#{lib_dirs}}/**/*.#{dlext}")
  end

  # Private: Calls the code necessary to build all the extensions
  # into a specified install root
  #
  # Returns a list of files beneath that root making up the build
  # products of the extensions
  #
  def build_extensions(install_root)
    tempdir do |workroot|

      @package.extract_files workroot
      @package.spec.extension_dir = install_root
      @package.spec.installed_by_version = Gem::VERSION
      @package.spec.build_extensions

      Dir.glob(File.join(install_root, "**", "*"))
    end
  end


  # Public: Compile
  #
  #
  def compile
    FileUtils.mkdir_p(@target_dir)

    tempdir do |path|

      targz_file(output_path) do |tar_writer|

        build_extensions(path).each do |product_path|
          next if File.directory?(product_path)
          product_path = Pathname.new(product_path)
          relative_path = product_path.relative_path_from(Pathname.new(path))

          stat = File.stat(product_path)
          mode = stat.mode
          size = stat.size

          File.open(product_path, "r") do |source|

            tar_writer.add_file_simple(relative_path.to_s, mode, size) do |dest|
              dest.write source.read(1024*1024) until source.eof?
            end
          end

        end

      end
    end
  end

  # Private: Yield a reference to a TarWriter that writes to
  # the specified .tar.gz file
  #
  def targz_file(path, &block)
    Zlib::GzipWriter.open(path) do |tar_file_io|
      Gem::Package::TarWriter.new(tar_file_io, &block)
    end
  end

end
