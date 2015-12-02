module CurationConcerns
  module FileSet
    module Querying
      extend ActiveSupport::Concern

      module ClassMethods
        def where_digest_is(digest_string)
          where Solrizer.solr_name('digest', :symbol) => urnify(digest_string)
        end

        def urnify(digest_string)
          "urn:sha1:#{digest_string}"
        end
      end
    end
  end
end
