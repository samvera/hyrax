module Qa::Authorities
  class FindWorks < Qa::Authorities::Base
    def search(_q, controller)
      repo = CatalogController.new.repository
      builder = Sufia::FindWorksSearchBuilder.new(controller)
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
