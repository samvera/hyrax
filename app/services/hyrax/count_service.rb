module Hyrax
  class CountService
    attr_reader :context, :search_builder, :model
    class_attribute :default_search_builder
    self.default_search_builder = Hyrax::AdminSetSearchBuilder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context, search_builder = default_search_builder, model = ::AdminSet)
      @context = context
      @search_builder = search_builder
      @model = model
    end

    # @param [Symbol] access :deposit, :read or :edit
    def search_results(access)
      response = context.repository.search(builder(access))
      response.documents
    end

    protected
      def last_updated(results)
        dates = []

        results['response']['docs'].each do |doc|
          # dates << DateTime.parse(doc['date_modified_dtsi']).strftime("%Y-%m-%d")
          dates << DateTime.parse(doc['system_modified_dtsi']).strftime("%Y-%m-%d")
        end

        dates.sort!
        dates.last
      end

      # @param [Symbol] access :read or :edit
      def builder(access)
        search_builder.new(context, access, @model).rows(100)
      end
  end
end