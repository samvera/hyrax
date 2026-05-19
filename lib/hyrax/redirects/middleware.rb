# frozen_string_literal: true

module Hyrax
  module Redirects
    # Rack middleware that resolves registered alias paths. Runs in front
    # of Rails routing so it can either rewrite the request path (for
    # display URLs) or short-circuit with a 301 response (for non-display
    # aliases). Adopters who need tenant-aware cache keys can override
    # `.cache_key_for` with a class-level decorator.
    class Middleware
      CACHE_TTL = 60.seconds

      def self.cache_key_for(path)
        Hyrax::RedirectCacheBuster.cache_key_for(path)
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless intercept?(env)

        path = Hyrax::RedirectPathNormalizer.call(env['PATH_INFO'])
        return @app.call(env) if skip_path?(path)

        resolution = Rails.cache.fetch(self.class.cache_key_for(path), expires_in: CACHE_TTL) do
          Hyrax::Redirects::Resolver.call(path)
        end

        dispatch(resolution, env)
      end

      private

      def intercept?(env)
        %w[GET HEAD].include?(env['REQUEST_METHOD']) && Hyrax.config.redirects_active?
      end

      def skip_path?(path)
        return true if path.blank? || path == '/'
        Hyrax.config.reserved_redirect_prefixes.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
      end

      def dispatch(resolution, env)
        return @app.call(env) if resolution.nil?
        return render_in_place(resolution[:render_path], env) if resolution[:render_path]
        redirect_response(resolution[:redirect_to]) if resolution[:redirect_to]
      end

      def render_in_place(render_path, env)
        env['hyrax.redirects.rewrote'] = true
        original_path = env['PATH_INFO']
        env['PATH_INFO'] = render_path
        status, headers, body = @app.call(env)
        headers['Turbolinks-Location'] = original_path
        [status, headers, body]
      end

      def redirect_response(target)
        headers = {
          'Location' => target,
          'Content-Type' => 'text/html',
          'Cache-Control' => 'no-cache',
          'Turbolinks-Location' => target
        }
        [301, headers, []]
      end
    end
  end
end
