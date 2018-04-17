module Riiif
  class FedoraHTTPFileResolver < Riiif::HTTPFileResolver
    def find(id)
      remote = Riiif::FedoraHTTPFileResolver::RemoteFile.new(uri(id),
                              cache_path: cache_path,
                              basic_auth_credentials: basic_auth_credentials)
      Riiif::File.new(remote.fetch)
    end

    class RemoteFile < Riiif::HTTPFileResolver::RemoteFile
      include ActiveSupport::Benchmarkable
      delegate :logger, to: :Rails
      attr_reader :url, :cache_path
      def initialize(url, options = {})
        @url = url
        @options = options
      end

      def cache_path
        @options.fetch(:cache_path)
      end

      def basic_auth_credentials
        @options[:basic_auth_credentials]
      end

      def fetch
        puts "Deleting cached original" if ::File.exists?(file_name) && expired?
        ::File.delete(file_name) if ::File.exists?(file_name) && expired?
        download_file unless ::File.exist?(file_name)
        file_name
      end

      def expired?
        # Do a HEAD request and check If-Modified-Since cache modification time
        uri = URI(url)
        req = Net::HTTP::Head.new(uri)
        req['If-Modified-Since'] = cache_mtime.rfc2822
        res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req) }
        # If the file has changed it will return 200 OK
        # and if the file hasn't changed it returns 304 NOT MODIFIED
        res.is_a? Net::HTTPOK
      end

      private

        def ext
          @ext ||= ::File.extname(URI.parse(url).path)
        end

        def file_name
          @cache_file_name ||= ::File.join(cache_path, Digest::MD5.hexdigest(url) + ext.to_s)
        end

        def download_file
          ensure_cache_path(::File.dirname(file_name))
          benchmark("Riiif downloaded #{url}") do
            ::File.atomic_write(file_name, cache_path) do |local|
              begin
                Kernel.open(url, download_opts) do |remote|
                  while chunk = remote.read(8192)
                    local.write(chunk)
                  end
                end
              rescue OpenURI::HTTPError => e
                raise ImageNotFoundError, e.message
              end
            end
          end
        end

        # Get a hash of options for passing to Kernel::open
        # This is the primary pathway for passing basic auth credentials
        def download_opts
          basic_auth_credentials ? { http_basic_authentication: basic_auth_credentials } : {}
        end

        # Make sure a file path's directories exist.
        def ensure_cache_path(path)
          FileUtils.makedirs(path) unless ::File.exist?(path)
        end

        def cache_mtime
          ::File.new(file_name).mtime
        end
    end
  end
end
