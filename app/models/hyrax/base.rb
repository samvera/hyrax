module Hyrax
  class Base
    def self.search_by_id(id, opts = {})
      opts = opts.merge(rows: 1)
      result = Hyrax::SolrService.query("id:#{id}", opts)

      raise ActiveFedora::ObjectNotFoundError, "Object '#{id}' not found in solr" if result.empty?
      result.first
    end
  end
end
