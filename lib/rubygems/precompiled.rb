# require 'rubygems/precompiled/version'
# require 'rubygems/installer'
# require 'rubygems/ext/builder'
# require 'rubygems/package/tar_reader'
# require 'zlib'
# require 'fileutils'
# require 'net/http'
# require 'uri'
# require 'tempfile'

# class Gem::Installer

#   def build_extensions_with_cache
#     unless @spec.extensions.empty?
#       cache_key = "/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}/#{Gem::Platform.local.to_s}/#{@spec.name}-#{@spec.version}.tgz"
#       local_copy = consult_build_artifact_cache(cache_key)
#       if local_copy
#         puts "Skipping build with cache"

#         puts "Extracting to #{gem_dir}"

#         Zlib::GzipReader.open(local_copy) do |gzip_io|
#           Gem::Package::TarReader.new(gzip_io) do |tar|
#             tar.each do |entry|
#               target_path = File.join(gem_dir, entry.full_name)
#               if entry.directory?
#                 puts "  creating directory #{target_path}"
#                 FileUtil.mkdir_p(target_path)
#               elsif entry.file?
#                 puts "  #{entry.full_name} -> #{target_path}"
#                 File.open(target_path, "w") do |f|
#                   f.write entry.read(1024) until entry.eof?
#                 end
#               end
#               entry.close
#             end
#           end
#         end
#       else
#         puts "Cached build not found."
#         build_extensions_without_cache
#       end
#     end
#   end

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

#   alias_method :build_extensions_without_cache, :build_extensions
#   alias_method :build_extensions, :build_extensions_with_cache
# end