require 'rubygems/precompiled/version'
require 'rubygems/installer'
require 'rubygems/ext/builder'
require 'rubygems/package/tar_reader'
require 'zlib'
require 'fileutils'
require 'net/http'
require 'uri'
require 'tempfile'

module Precompiled

  def self.included(base)
    base.send(:alias_method, :build_extensions_without_cache, :build_extensions)
    base.send(:alias_method, :build_extensions, :build_extensions_with_cache)
  end

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
    def uri_to_spec(spec)
      URI.join(@root_uri, File.join(@root_uri.path, cache_key(spec)))
    end
    def contains?(spec)
      uri = uri_to_spec(spec)
      http = Net::HTTP.start(uri.host, uri.port)
      http.head(uri.path).code == "200"
    end
    def retrieve(spec)
      tempfile = Tempfile.new('cache-hit')
      uri = uri_to_spec(spec)
      http = Net::HTTP.start(uri.host, uri.port)
      http.request_get(uri.path) do |resp|
        resp.read_body do |segment|
          tempfile.write(segment)
        end
        tempfile.close
      end

      yield tempfile
      tempfile.delete
    end
  end

  GemCache = {
    'file' => FileCache,
    'http' => HttpCache
  }.freeze

  # Private: A list of precompiled cache root URLs loaded from the rubygems configuration file
  #
  # Returns Array of BaseCache subclasses
  def self.precompiled_caches
    @@caches ||= [Gem.configuration['precompiled_cache']].flatten.compact.map do |cache_root|
      cache_root = URI.parse(cache_root)
      GemCache[cache_root.scheme].new(cache_root)
    end
  end

  def build_extensions_with_cache
    spec = @package.spec
    cache = Precompiled.precompiled_caches.find { |cache| cache.contains?(spec) }

    if cache
      $stderr.puts "Loading native extension from cache"
      cache.retrieve(spec) do |path|
        if spec.respond_to?(:extension_dir)
          overlay_tarball(path, spec.extension_dir)
        else
          overlay_tarball(path, @gem_dir)
        end
      end
    else
      build_extensions_without_cache
    end
  end

  # Private: Extracts a .tar.gz file on-top of the gem's installation directory
  def overlay_tarball(tarball, target_root)
    Zlib::GzipReader.open(tarball) do |gzip_io|
      Gem::Package::TarReader.new(gzip_io) do |tar|
        tar.each do |entry|
          target_path = File.join(target_root, entry.full_name)
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

end

Gem::Installer.send(:include, Precompiled)
