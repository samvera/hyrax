# frozen_string_literal: true
module Hyrax::HasRendering
  extend ActiveSupport::Concern

  included do
    # rubocop:disable Rails/HasAndBelongsToMany
    has_and_belongs_to_many :renderings,
                            predicate: Hyrax.config.rendering_predicate,
                            class_name: 'ActiveFedora::Base'
    # rubocop:enable Rails/HasAndBelongsToMany
  end
end
