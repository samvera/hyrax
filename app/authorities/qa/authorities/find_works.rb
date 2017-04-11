module Qa::Authorities
  class FindWorks < Qa::Authorities::Base
    class_attribute :search_builder_class
    self.search_builder_class = Hyrax::My::FindWorksSearchBuilder

    def search(_q, controller)
      repo = CatalogController.new.repository
      builder = search_builder(controller)
      response = repo.search(builder)
      docs = response.documents
      docs.map do |doc|
        id = doc.id
        title = doc.title
        { id: id, label: title, value: id }
      end
    end

    private

      def search_builder(controller)
        search_builder_class.new(controller)
      end
  end
end
