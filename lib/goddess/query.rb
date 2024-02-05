# frozen_string_literal: true
module Goddess
  module Query
    extend ActiveSupport::Concern
    included do
      attr_reader :services
      delegate :orm_class, to: :resource_factory

      [:find_all,
       :find_all_of_model,
       :find_many_by_ids,
       :find_members,
       :find_references_by,
       :find_inverse_references_by,
       :find_inverse_references_by,
       :find_parents].each do |method_name|
        find_multiple(method_name)
      end

      [:find_by,
       :find_by_alternate_identifier].each do |method_name|
        find_single(method_name)
      end

      [:count_all_of_model].each do |method_name|
        count_multiple(method_name)
      end
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      # NOTE: - we dont have a good way to remove items in both from the count since we dont want to load all
      # of the items and de-dup them. There for we just return the highest number among the counts. This will be
      # inaccurate if you start adding new items to the target repo while migrating
      def count_multiple(method_name)
        # look in all services, combine and uniq results
        define_method method_name do |*args, **opts|
          opts[:model] = setup_model(opts[:model]) if opts[:model]
          result_sets = []
          services.each do |service|
            result = service.send(method_name, *args, **opts)
            result_sets << result if result.present?
          rescue Valkyrie::Persistence::ObjectNotFoundError
            next
          end

          result_sets.max
        end
      end

      def find_multiple(method_name)
        # look in all services, combine and uniq results
        define_method method_name do |*args, **opts|
          opts[:model] = setup_model(opts[:model]) if opts[:model]
          result_sets = []
          services.each do |service|
            result = service.send(method_name, *args, **opts)
            result_sets << result.to_a if result.present? && result.respond_to?(:any?) && result.any?
          rescue Valkyrie::Persistence::ObjectNotFoundError
            next
          end

          # We need to remove items in both sets, but not remove duplicates with in the set
          # because Valkyrie specifies that relationships can be duplicated (A can have [B, C, B, D] as children)
          total_results(result_sets)
        end
      end

      def find_single(method_name)
        define_method method_name do |*args, **opts|
          opts[:model] = setup_model(opts[:model]) if opts[:model]
          result = nil
          services.each do |service|
            result = service.send(method_name, *args, **opts)
            return result if result.present?
          rescue Valkyrie::Persistence::ObjectNotFoundError
            next
          end

          return result unless result.nil?
          raise Valkyrie::Persistence::ObjectNotFoundError
        end
      end
    end

    # @param [QueryService] query_service
    def initialize(*services)
      @services = services
    end

    def model_class_for(model)
      internal_resource = model.respond_to?(:internal_resource) ? model.internal_resource : nil
      internal_resource&.safe_constantize || Wings::ModelRegistry.lookup(model)
    end

    def setup_model(model_name)
      model_name = model_class_for(model_name)
      model_name.respond_to?(:valkyrie_class) ? model_name.valkyrie_class : model_name
    end

    def total_results(result_sets)
      if result_sets.present?
        total_result = result_sets.inject([]) do |out, set|
          i = out.intersection(set)
          out + (set - i)
        end
        total_result
      else
        result_sets
      end
    end
  end
end
