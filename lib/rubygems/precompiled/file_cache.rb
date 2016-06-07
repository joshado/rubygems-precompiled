require "rubygems/precompiled/base_cache"

module Precompiled
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
end
