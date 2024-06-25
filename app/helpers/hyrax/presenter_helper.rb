# frozen_string_literal: true

module Hyrax
  module PresenterHelper
    def view_options_for(presenter)
      Hyrax::Schema.schema_to_hash_for(presenter.model.class).select { |_, val| val['view'].present? }
    end
  end
end
