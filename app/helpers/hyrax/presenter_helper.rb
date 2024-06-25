# frozen_string_literal: true

module Hyrax
  module PresenterHelper
    def view_options_for(presenter)
      model_name = presenter.model.model_name.name.constantize
      hash = Hyrax::Schema.schema_to_hash_for(model_name) ||
               Hyrax::Schema.schema_to_hash_for((model_name.to_s + 'Resource').safe_constantize)

      hash.select { |_, val| val['view'].present? }
    end
  end
end
