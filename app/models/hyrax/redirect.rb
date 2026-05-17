# frozen_string_literal: true

module Hyrax
  ##
  # Wraps a single redirect entry for use in form views, providing
  # `.path` and `.display` readers over the underlying persisted hash.
  #
  # Redirects are persisted as plain hashes on the parent work or
  # collection. Form-render code calls `Hyrax::Redirect.wrap(entry)` to
  # get a value object the view can call methods on. Other code (the
  # validator, indexer, sync step) reads the persisted hash directly.
  #
  # @example
  #   Hyrax::Redirect.new(path: '/handle/12345/678', display: false)
  #   Hyrax::Redirect.wrap('path' => '/foo', 'display' => true)
  class Redirect
    attr_reader :path, :display

    ##
    # Accept nil values so the view can build an empty trailing row.
    def initialize(path: nil, display: false)
      @path = path
      @display = display
    end

    ##
    # Build a presenter from a hash. If passed a presenter, returns it
    # unchanged. Returns nil for nil input. Accepts string or symbol keys.
    #
    # @param input [Hyrax::Redirect, Hash, nil]
    # @return [Hyrax::Redirect, nil]
    def self.wrap(input)
      return nil if input.nil?
      return input if input.is_a?(Hyrax::Redirect)
      raise ArgumentError, "cannot wrap #{input.class} as Hyrax::Redirect" unless input.respond_to?(:to_h)

      h = input.to_h.transform_keys(&:to_s)
      new(path: h['path'], display: h.fetch('display', false))
    end

    ##
    # @return [Hash{String => Object}] string-keyed hash matching the persisted shape.
    def to_h
      { 'path' => path, 'display' => display }
    end

    def as_json(*)
      to_h
    end

    ##
    # Equality on attribute values, so `Array#uniq` works as expected.
    def ==(other)
      other.is_a?(Hyrax::Redirect) &&
        other.path == path &&
        other.display == display
    end
    alias eql? ==

    def hash
      [path, display].hash
    end
  end
end
