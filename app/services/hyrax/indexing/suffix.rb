module Hyrax
  module Indexing
    class Suffix
      def initialize(*fields)
        @fields = fields.flatten
      end

      def multivalued?
        field? :multivalued
      end

      def stored?
        field? :stored
      end

      def indexed?
        field? :indexed
      end

      def field?(f)
        (f.to_sym == :type) || @fields.include?(f.to_sym)
      end

      def data_type
        @fields.first
      end

      def to_s
        raise InvalidIndexDescriptor, "Missing datatype for #{@fields}" unless data_type

        field_suffix = [config.suffix_delimiter]

        config.fields.select { |f| field? f }.each do |f|
          key = :"#{f}_suffix"
          field_suffix << if config.send(key).is_a? Proc
                            config.send(key).call(@fields)
                          else
                            config.send(key)
                          end
        end

        field_suffix.join
      end

      def self.config
        # TODO: `:symbol' usage ought to be deprecated
        # See https://github.com/samvera/active_fedora/issues/1334
        @config ||= OpenStruct.new fields: [:type, :stored, :indexed, :multivalued],
                                   suffix_delimiter: '_',
                                   type_suffix: (lambda do |fields|
                                                   type = fields.first
                                                   case type
                                                   when :string, :symbol
                                                     's'
                                                   when :text
                                                     't'
                                                   when :text_en
                                                     'te'
                                                   when :date, :time
                                                     'dt'
                                                   when :integer
                                                     'i'
                                                   when :boolean
                                                     'b'
                                                   when :long
                                                     'lt'
                                                   when :float, :big_decimal
                                                     'f'
                                                   else
                                                     raise InvalidIndexDescriptor, "Invalid datatype `#{type.inspect}'. Must be one of: :date, :time, :text, :text_en, :string, :symbol, :integer, :boolean"
                                                   end
                                                 end),
                                   stored_suffix: 's',
                                   indexed_suffix: 'i',
                                   multivalued_suffix: 'm'
      end

      def config
        @config ||= self.class.config.dup
      end
    end
  end
end
