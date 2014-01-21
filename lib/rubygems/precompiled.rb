require 'rubygems/precompiled/version'
require 'rubygems/installer'
require 'rubygems/ext/builder'
require 'rubygems/package/tar_reader'
require 'zlib'
require 'fileutils'
# require 'net/http'
require 'uri'
# require 'tempfile'

class Gem::Installer

  class BaseCache
    def initialize(root_uri)
      @root_uri = root_uri
    end

    def retrieve(spec)
      raise "Must be overriden!"
    end
    def contains?(spec)
      false
    end
    def cache_key(spec)
      "/ruby-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}/#{Gem::Platform.local.to_s}/#{spec.name}-#{spec.version}.tar.gz"
    end
  end

  class FileCache < BaseCache
    def path_for(spec)
      File.join(@root_uri.path, cache_key(spec))
    end
    def contains?(spec)
      File.exists?(path_for(spec))
    end

    def retrieve(spec)
      yield path_for(spec)
    end
  end

  class HttpCache < BaseCache
    def contains?(spec)
      false
    end
    def retrieve(spec)
      super(spec)
    end
  end

  GemCache = {
    'file' => FileCache,
    'http' => HttpCache
  }.freeze

  # Private: A list of precompiled cache root URLs loaded from the rubyges configuration file
  #
  # Returns Array of BaseCache subclasses
  def self.precompiled_caches
    @@caches ||= [Gem.configuration['precompiled_cache']].flatten.compact.map do |cache_root|
      cache_root = URI.parse(cache_root)
      GemCache[cache_root.scheme].new(cache_root)
    end
  end

  def build_extensions_with_cache
    cache = Gem::Installer.precompiled_caches.find { |cache| cache.contains?(@spec) }

    if cache
      puts "Loading native extension from cache"
      cache.retrieve(@spec) do |path|
        overlay_tarball(path)
      end
    else
      build_extensions_without_cache
    end
  end

  alias_method :build_extensions_without_cache, :build_extensions
  alias_method :build_extensions, :build_extensions_with_cache

  # Private: Extracts a .tar.gz file on-top of the gem's installation directory
  def overlay_tarball(tarball)
    puts tarball
    Zlib::GzipReader.open(tarball) do |gzip_io|
      Gem::Package::TarReader.new(gzip_io) do |tar|
        tar.each do |entry|
          target_path = File.join(gem_dir, entry.full_name)
          if entry.directory?
            FileUtils.mkdir_p(target_path)
          elsif entry.file?
            FileUtils.mkdir_p(File.dirname(target_path))
            File.open(target_path, "w") do |f|
              f.write entry.read(1024*1024) until entry.eof?
            end
          end
          entry.close
        end
      end
    end
  end

#     unless @spec.extensions.empty?
#       cache_key = "/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}/#{Gem::Platform.local.to_s}/#{@spec.name}-#{@spec.version}.tgz"
#       local_copy = consult_build_artifact_cache(cache_key)
#       if local_copy
#         puts "Skipping build with cache"

#         puts "Extracting to #{gem_dir}"

#         end
#       else

#       end
#     end


#   def prebuild_cache_root
#     ENV['PREBUILD_CACHE_ROOT']
#   end

#   # Look in the build-artifact cache for a bundle.
#   #
#   # If one exists, download it and return the path as a string
#   # If not, return nil
#   def consult_build_artifact_cache(cache_key)
#     return if prebuild_cache_root.nil?

#     uri = URI.parse("#{prebuild_cache_root}#{cache_key}")
#     puts "Trying #{uri}"
#     if uri.scheme == 'http'
#       response = Net::HTTP.get_response(uri)
#       if response.code == '200'
#         file = Tempfile.new('downloaded-file')
#         file.write response.body
#         file.path
#       else
#         nil
#       end
#     elsif uri.scheme == 'file'
#       File.exist?(uri.path) ? uri.path : nil
#     end
#   end

end