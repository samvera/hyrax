# frozen_string_literal: true

module Hyrax
  ##
  # @deprecated use +Hyrax::Indexers::FileSetIndexer+ instead
  class ValkyrieFileSetIndexer < Hyrax::Indexers::FileSetIndexer
    def initialize(*args, **kwargs)
      Deprecation.warn "`Hyrax::ValkyrieFileSetIndexer` is deprecated. Use `Hyrax::Indexers::FileSetIndexer` instead."
      super
    end
  end
end
