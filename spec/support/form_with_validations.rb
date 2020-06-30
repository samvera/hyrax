# frozen_string_literal: true
module Hyrax
  module Test
    class FormWithValidations < Hyrax::Forms::ResourceForm
      property :title

      validates :title, presence: true
    end
  end
end
