# frozen_string_literal: true

module Hyrax
  ##
  # @deprecated use +Hyrax::Indexers::PcdmCollectionIndexer+ instead
  class PcdmCollectionIndexer < Hyrax::Indexers::PcdmCollectionIndexer
    def initialize(*args, **kwargs)
      Deprecation.warn "`Hyrax::PcdmCollectionIndexer` is deprecated. Use `Hyrax::Indexers::PcdmCollectionIndexer` instead."
      super
    end
  end
end
