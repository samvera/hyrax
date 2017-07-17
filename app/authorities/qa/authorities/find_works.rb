module Qa::Authorities
  class FindWorks < Qa::Authorities::Base
    def search(_q, controller)
      # The FindWorksSearchBuilder expects a current_user
      return [] unless controller.current_user
      repo = CatalogController.new.repository
      builder = Hyrax::FindWorksSearchBuilder.new(controller)
      response = repo.search(builder)
      docs = response.documents
      docs.map do |doc|
        id = doc.id
        title = doc.title
        { id: id, label: title, value: id }
      end
    end
  end
end
