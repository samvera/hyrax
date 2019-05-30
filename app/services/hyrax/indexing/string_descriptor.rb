module Hyrax
  module Indexing
    class StringDescriptor < Descriptor
      def initialize(suffix)
        @suffix = suffix
      end

      def suffix(_field_type)
        '_' + @suffix
      end
    end
  end
end
