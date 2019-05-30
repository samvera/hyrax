module Hyrax
  module Indexing
    extend ActiveSupport::Concern

    class FieldMapper
      class_attribute :id_field, :descriptors
      # set defaults
      self.id_field = 'id'
      self.descriptors = [DefaultDescriptors]

      # @api
      # @params [Hash] doc the hash to insert the value into
      # @params [String] name the name of the field (without the suffix)
      # @params [String,Date] value the value to be inserted
      # @params [Array,Hash] indexer_args the arguments that find the indexer
      # @returns [Hash] doc the document that was provided with the new field (replacing any field with the same name)
      def set_field(doc, name, value, *indexer_args)
        # adding defaults indexer
        indexer_args = [:stored_searchable] if indexer_args.empty?
        doc.merge! solr_names_and_values(name, value, indexer_args)
        doc
      end

      # @api
      # Given a field name, index_type, etc., returns the corresponding Solr name.
      # TODO field type is the input format, maybe we could just detect that?
      # See https://github.com/samvera/active_fedora/issues/1338
      # @param [String] field_name the ruby (term) name which will get a suffix appended to become a Solr field name
      # @param opts - index_type is only needed if the FieldDescriptor requires it (e.g. :searcahble)
      # @return [String] name of the solr field, based on the params
      def solr_name(field_name, *opts)
        index_type, args = if opts.first.is_a? Hash
                             [:stored_searchable, opts.first]
                           elsif opts.empty?
                             [:stored_searchable, { type: :text }]
                           else
                             [opts[0], opts[1] || { type: :string }]
                           end

        descriptor = indexer(index_type)
        names = descriptor.name_and_converter(field_name, args)
        names.first
      end

      # Given a field name-value pair, a data type, and an array of index types, returns a hash of
      # mapped names and values. The values in the hash are _arrays_, and may contain multiple values.
      def solr_names_and_values(field_name, field_value, index_types)
        return {} if field_value.nil?

        # Determine the set of index types
        index_types = Array(index_types)
        index_types.uniq!
        index_types.dup.each do |index_type|
          if index_type.to_s =~ /^not_(.*)/
            index_types.delete index_type # not_foo
            index_types.delete Regexp.last_match(1).to_sym # foo
          end
        end

        # Map names and values

        results = {}

        # Time seems to extend enumerable, so wrap it so we don't interate over each of its elements.
        field_value = [field_value] if field_value.is_a? Time

        index_types.each do |index_type|
          Array(field_value).each do |single_value|
            # Get mapping for field
            descriptor = indexer(index_type)
            data_type = extract_type(single_value)
            name, _converter = descriptor.name_and_converter(field_name, type: data_type)
            next unless name

            # Is there a custom converter?
            # TODO instead of a custom converter, look for input data type and output data type. Create a few methods that can do that cast.
            # See https://github.com/samvera/active_fedora/issues/1339

            # The converter requires that the Descriptor be constructed with the
            # :converter option
            # value = if converter
            #           if converter.arity == 1
            #             converter.call(single_value)
            #           else
            #             converter.call(single_value, field_name)
            #           end
            #         elsif data_type == :boolean
            #           single_value
            #         else
            #           single_value.to_s
            #         end
            value = if data_type == :boolean
                      single_value
                    else
                      single_value.to_s
                    end

            # Add mapped name & value, unless it's a duplicate
            if descriptor.evaluate_suffix(data_type).multivalued?
              values = (results[name] ||= [])
              values << value unless value.nil? || values.include?(value)
            else
              Hyrax.logger.warn "Setting #{name} to `#{value}', but it already had `#{results[name]}'" if results[name]
              results[name] = value
            end
          end
        end

        results
      end

      private

        # @param [Symbol, String, Descriptor] index_type is a Descriptor, a symbol that references a method that returns a Descriptor, or a string which will be used as the suffix.
        # @return [Descriptor]
        def indexer(index_type)
          index_type = case index_type
                       when Symbol
                         index_type_macro(index_type)
                       when String
                         StringDescriptor.new(index_type)
                       when Descriptor
                         index_type
                       else
                         raise InvalidIndexDescriptor, "#{index_type.class} is not a valid indexer_type. Use a String, Symbol or Descriptor."
                       end

          raise InvalidIndexDescriptor, "index type should be an Descriptor, you passed: #{index_type.class}" unless index_type.is_a?(Descriptor)
          index_type
        end

        # @param index_type [Symbol]
        # search through the descriptors (class attribute) until a module is found that responds to index_type, then call it.
        def index_type_macro(index_type)
          klass = self.class.descriptors.find { |descriptor_klass| descriptor_klass.respond_to? index_type }

          raise UnknownIndexMacro, "Unable to find `#{index_type}' in #{self.class.descriptors}" if klass.nil?

          klass.send(index_type)
        end

        def extract_type(value)
          case value
          when NilClass
            nil
          when Integer # In ruby < 2.4, Fixnum extends Integer
            :integer
          when DateTime
            :time
          when TrueClass, FalseClass
            :boolean
          else
            value.class.to_s.underscore.to_sym
          end
        end
    end
  end
end
