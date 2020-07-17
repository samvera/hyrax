# frozen_string_literal: true
module Hyrax
  module Identifier
    ##
    # Builds an identifier string.
    #
    # Implementations must accept a `prefix:` to `#initialize`, and a `hint:` to
    # `#build`. Either or both may be used at the preference of the specific
    # implementer or ignored entirely when `#build` is called.
    #
    # @example
    #   builder = Hyrax::Identifier::Builder.new(prefix: 'moomin')
    #   builder.build(hint: '1') # => "moomin/1"
    class Builder
      ##
      # @!attribute prefix [rw]
      #   @return [String] the prefix to use when building identifiers
      attr_accessor :prefix

      ##
      # @param prefix [String] the prefix to use when building identifiers
      def initialize(prefix: 'pfx')
        @prefix = prefix
      end

      ##
      # @note this default builder requires a `hint` which it appends to the
      #   prefix to generate the identifier string.
      #
      # @param hint [#to_s] a string-able object which may be used by the builder
      #   to generate an identifier. Hints may be required by some builders, while
      #   others may ignore them to generate an identifier by other means.
      #
      # @return [String]
      # @raise [ArgumentError] if an identifer can't be built from the provided
      #   hint.
      def build(hint: nil)
        raise(ArgumentError, "No hint provided to #{self.class}#build") if
          hint.nil?

        "#{prefix}/#{hint}"
      end
    end
  end
end
