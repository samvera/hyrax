# frozen_string_literal: true

module Hyrax
  ##
  # @deprecated use +Hyrax::Indexers::PcdmCollectionIndexer+ instead
  class ValkyrieCollectionIndexer < Hyrax::PcdmCollectionIndexer # also deprecated
    def initialize(*args, **kwargs)
      Deprecation.warn "`Hyrax::ValkyrieCollectionIndexer` is deprecated. Use `Hyrax::Indexers::PcdmCollectionIndexer` instead."
      super
    end
  end
end
