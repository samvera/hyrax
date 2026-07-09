# frozen_string_literal: true

module Hyrax
  # Normalizes a user- or system-supplied redirect path into the canonical
  # form stored in `hyrax_redirect_paths` and queried by the resolver.
  # Single source of truth for "what does this path look like on disk?".
  #
  # Normalization rules:
  # 1. If input parses as a URL with scheme/host, keep only the path component
  #    (drop scheme, host, port, userinfo, query, fragment).
  # 2. Strip query strings and fragments from path-only inputs.
  # 3. Ensure a leading slash.
  # 4. Strip trailing slashes (but never reduce the path to empty).
  #
  # Idempotent: normalize(normalize(x)) == normalize(x).
  #
  # See documentation/redirects.md.
  module RedirectPathNormalizer
    module_function

    def call(input)
      return input if input.nil?
      path = input.to_s.strip
      return path if path.empty?

      path = extract_path(path)
      path = strip_query_and_fragment(path)
      path = ensure_leading_slash(path)
      path = strip_trailing_slashes(path)
      path
    end

    def extract_path(path)
      return path unless path.match?(%r{\A[a-zA-Z][a-zA-Z0-9+.-]*://})
      uri = URI.parse(path)
      uri.path.presence || '/'
    rescue URI::InvalidURIError
      path
    end
    private_class_method :extract_path

    def strip_query_and_fragment(path)
      path.sub(/[?#].*\z/, '')
    end
    private_class_method :strip_query_and_fragment

    def ensure_leading_slash(path)
      path.start_with?('/') ? path : "/#{path}"
    end
    private_class_method :ensure_leading_slash

    def strip_trailing_slashes(path)
      stripped = path.sub(/\/+\z/, '')
      stripped.empty? ? '/' : stripped
    end
    private_class_method :strip_trailing_slashes
  end
end
