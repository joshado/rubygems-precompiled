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
    @installer = Gem::Installer.new(gemfile, opts.dup.merge(:unpack => true, :build_args => opts.fetch(:build_config,[])))
    @spec = @installer.spec

    @target_dir = opts.fetch(:output, Dir.pwd)
    @target_dir = File.join(@target_dir, arch_string) if opts.fetch(:arch, false)
    @debug = opts.fetch(:debug, false)
    @options = opts

    # This writes out a build_info file that the extension builder will process to set the
    # build configuration. We use the write_build_info_file method which should work on ruby 2+
    # on ruby  < 1.9.3 we don't support setting of build options. 1.9.3 is EOL.
    # However most simple gems that do not require build time config will still work.
    return if opts.fetch(:build_config,[]).empty?

    if Gem::Installer.method_defined?(:write_build_info_file)
      @installer.write_build_info_file
    else
      puts("Older version of rubygems, rubygems-precompiled does not support build options on this rubygems release (pull req welcome)")
      puts("Try again without build configuration")
      exit(1)
    end
  end

  # Private: Extracts the gem files into the specified path
  #
  def extract_files_into(dir)
    @installer.unpack(dir)
  end

  # Public: Returns the name of the gem
  #
  # Returns a string
  def gem_name
    @spec.name
  end

  # Public: Returns the version string of the gem
  #
  # Returns a Gem::Version
  def gem_version
    @spec.version
  end

  # Public: Returns the relative require-paths specified by the gem
  #
  # Returns an array of strings
  def gem_require_paths
    @spec.require_paths
  end

  # Public: Does the gem actually have any compiled extensions?
  #
  # Returns boolean - true if the gem has a c-extension that needs building
  def has_extension?
    !@spec.extensions.empty?
  end

  # Private: Yield the path to a temporary directory that will get deleted when
  # the block returns, unless debug option was used on the cli
  #
  def tempdir
    temp_dir = Dir.mktmpdir
    yield temp_dir
  ensure
    if @debug
      puts("\nLeaving #{temp_dir} in place")
    else
      rm_rf temp_dir
    end
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

  # Private: Calls the code necessary to build all the extensions
  # into a specified install root
  #
  # Returns a list of files beneath that root making up the build
  # products of the extensions
  #
  def build_extensions(install_root)
    if @spec.respond_to?(:extension_dir=)
      tempdir do |workroot|
        extract_files_into(workroot)

        # override the full_gem_path function so we can return
        # the directory we want. Otherwise by default the build process will
        # look for the gem installed in the usual place won't find it and will then
        # bail
        class <<@spec
          attr_accessor :workroot
          def full_gem_path
            return workroot
          end
        end
        @spec.workroot = workroot

        @spec.extension_dir = install_root
        @spec.installed_by_version = Gem::VERSION
        @spec.build_extensions
        Dir.glob(File.join(install_root, "**", "*"))
      end
    else
      extract_files_into(install_root)
      @installer.build_extensions

      dlext = RbConfig::CONFIG["DLEXT"]
      lib_dirs = gem_require_paths.join(',')
      Dir.glob("#{install_root}/{#{lib_dirs}}/**/*.#{dlext}")
    end
  end


  # Public: Compile
  #
  # This compiles into a temporary file, then moves into place. Otherwise we potentially confuse
  # the gem installer with partial files!
  #
  def compile
    temp_output = Tempfile.new('partial-output')
    tempdir do |path|

      targz_file(temp_output) do |tar_writer|

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

    FileUtils.mkdir_p(@target_dir)
    FileUtils.mv(temp_output.path, output_path)
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
