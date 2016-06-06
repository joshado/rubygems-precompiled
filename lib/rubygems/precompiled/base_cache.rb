module Precompiled
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
end
