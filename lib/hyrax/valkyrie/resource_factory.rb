# frozen_string_literal: true

module Hyrax
  module Valkyrie
    # we really want a class var here. maybe we could use a singleton instead?
    # rubocop:disable Style/ClassVars
    class ResourceFactory
      class ResourceClassCache
        attr_reader :cache

        def initialize
          @cache = {}
        end

        def fetch(key)
          @cache.fetch(key) do
            @cache[key] = yield
          end
        end
      end

      @@resource_class_cache = ResourceClassCache.new

      attr_accessor :pcdm_object

      def initialize(pcdm_object:)
        self.pcdm_object = pcdm_object
      end

      def self.for(pcdm_object)
        new(pcdm_object: pcdm_object).build
      end

      def build
        klass = @@resource_class_cache.fetch(pcdm_object) do
          # we need a local binding to the object for use in the class scope below
          pcdm_local = pcdm_object

          Class.new(::Valkyrie::Resource) do
            pcdm_local.send(:properties).each_key do |property_name|
              attribute property_name.to_sym, ::Valkyrie::Types::String
            end
          end
        end

        klass.new(id: pcdm_object.id, **attributes)
      end

      private

        def attributes
          pcdm_object.attributes.each_with_object({}) do |(name, values), mem|
            mem[name.to_sym] = normalize_values(values)
          end
        end

        def normalize_values(values)
          case values
          when ActiveTriples::Resource
            values.to_term
          when ActiveTriples::Relation
            values.map { |val| normalize_values(val) }
          else
            values
          end
        end
    end
    # rubocop:enable Style/ClassVars
  end
end
