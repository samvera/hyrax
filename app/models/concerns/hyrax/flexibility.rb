# frozen_string_literal: true

module Hyrax
  module Flexibility
    extend ActiveSupport::Concern
    included do
      attribute :schema_version,       Valkyrie::Types::String
      attr_accessor :form_definitions
    end

    class_methods do
      ## Override dry-struct 1.6.0 to enable redefining schemas on the fly
      def attributes(new_schema)
        keys = new_schema.keys.map { |k| k.to_s.chomp("?").to_sym }
        schema Hyrax::Resource.schema.schema(new_schema)

        define_accessors(keys)

        @attribute_names = nil

        direct_descendants = descendants&.select { |d| d.superclass == self }
        direct_descendants&.each do |d|
          inherited_attrs = new_schema.reject { |k, _| d.has_attribute?(k.to_s.chomp("?").to_sym) }
          d.attributes(inherited_attrs)
        end

        new_schema.each_key do |key|
          key = key.to_s.chomp('?')
          next if instance_methods.include?("#{key}=".to_sym)

          class_eval(<<-RUBY)
          def #{key}=(value)
            set_value("#{key}".to_sym, value)
          end
        RUBY
        end

        self
      end

      ## Override dry-struct 1.6.0 to filter attributes after schema reload happens
      def new(attributes = default_attributes, safe = false, &block) # rubocop:disable Style/OptionalBooleanParameter
        if attributes.is_a?(Struct)
          if equal?(attributes.class)
            attributes
          else
            # This implicit coercion is arguable but makes sense overall
            # in cases there you pass child struct to the base struct constructor
            # User.new(super_user)
            #
            # We may deprecate this behavior in future forcing people to be explicit
            new(attributes.to_h, safe, &block)
          end
        else
          load(attributes, safe)
        end
      rescue Dry::Types::CoercionError => e
        raise Dry::Error, "[#{self}.new] #{e}", e.backtrace
      end

      ## Read the schema from the database and load the correct schemas for the instance in to the class
      def load(attributes, safe = false)
        attributes[:schema_version] ||=  Hyrax::FlexibleSchema.order('id DESC').pick(:id)
        struct = allocate
        schema_version = attributes[:schema_version]
        struct.singleton_class.attributes(Hyrax::Schema(self, schema_version:).attributes)
        clean_attributes = safe ? struct.singleton_class.schema.call_safe(attributes) { |output = attributes| return yield output } : struct.singleton_class.schema.call_unsafe(attributes)
        struct.__send__(:initialize, clean_attributes)
        struct.form_definitions =
        struct
      end
    end

    # Override set_value from valkyrie 3.1.1 to enable dynamic schema loading
    def set_value(key, value)
      @attributes[key.to_sym] = self.singleton_class.schema.key(key.to_sym).type.call(value)
    end

    # Override inspect from dry-struct 1.6.0 to enable dynamic schema loading
    def inspect
      klass = self.singleton_class
      attrs = klass.attribute_names.map { |key| " #{key}=#{@attributes[key].inspect}" }.join
      "#<#{klass.name || klass.inspect}#{attrs}>"
    end
  end
end
