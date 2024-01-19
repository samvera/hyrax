# frozen_string_literal: true

module Hyrax
  ##
  # @deprecated use +Hyrax::Indexers::AdministrativeSetIndexer+ instead
  class AdministrativeSetIndexer < Hyrax::Indexers::AdministrativeSetIndexer
    def initialize(*args, **kwargs)
      Deprecation.warn "`Hyrax::AdministrativeSetIndexer` is deprecated. Use `Hyrax::Indexers::AdministrativeSetIndexer` instead."
      super
    end
  end
end
