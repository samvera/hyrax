# frozen_string_literal: true

module Hyrax
  ##
  # Wraps a single redirect entry for use in form views, providing
  # `.path`, `.canonical`, and `.sequence` readers over the underlying
  # persisted hash.
  #
  # Redirects are persisted as plain hashes on the parent work or
  # collection. Form-render code calls `Hyrax::Redirect.wrap(entry)` to
  # get a value object the view can call methods on. Other code (the
  # validator, indexer, sync step) reads the persisted hash directly.
  #
  # @example
  #   Hyrax::Redirect.new(path: '/handle/12345/678', canonical: false)
  #   Hyrax::Redirect.wrap('path' => '/foo', 'canonical' => true)
  class Redirect
    attr_reader :path, :canonical, :sequence

    ##
    # Accept nil values so the view can build an empty trailing row.
    def initialize(path: nil, canonical: false, sequence: nil)
      @path = path
      @canonical = canonical
      @sequence = sequence
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
      new(path: h['path'], canonical: h.fetch('canonical', false), sequence: h['sequence'])
    end

    ##
    # @return [Hash{String => Object}] string-keyed hash matching the persisted shape.
    def to_h
      { 'path' => path, 'canonical' => canonical, 'sequence' => sequence }
    end

    def as_json(*)
      to_h
    end

    ##
    # Equality on attribute values, so `Array#uniq` works as expected.
    def ==(other)
      other.is_a?(Hyrax::Redirect) &&
        other.path == path &&
        other.canonical == canonical &&
        other.sequence == sequence
    end
    alias eql? ==

    def hash
      [path, canonical, sequence].hash
    end
  end
end
