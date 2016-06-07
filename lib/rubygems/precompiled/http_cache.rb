require "rubygems/precompiled/base_cache"

module Precompiled
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
end
