# frozen_string_literal: true

module Hyrax
  ##
  # @deprecated use +Hyrax::Indexers::PcdmObjectIndexer+ instead
  class ValkyrieWorkIndexer < Hyrax::Indexers::PcdmObjectIndexer
    def initialize(*args, **kwargs)
      Deprecation.warn "`Hyrax::ValkyrieWorkIndexer` is deprecated. Use `Hyrax::Indexers::PcdmObjectIndexer` instead."
      super
    end
  end
end
