# frozen_string_literal: true

module Hyrax
  ##
  # Indexes visibility of the resource; Blacklight depends on visibility being
  # present in the index to determine visibility of results and object show
  # views.
  #
  # @example
  #   class MyIndexer < Hyrax::Indexers::ResourceIndexer
  #     include Hyrax::VisibilityIndexer
  #   end
  module VisibilityIndexer
    def to_solr
      super.tap do |index_document|
        index_document[:visibility_ssi] = visibility_reader.read
      end
    end

    private

    def visibility_reader
      Hyrax::VisibilityReader.new(resource: resource)
    end
  end
end
