# frozen_string_literal: true
module Hyrax
  module Test
    class FormWithValidations < Hyrax::Forms::ResourceForm
      property :title

      validates :title, presence: true

      # Added to comply with Hyrax::Forms::FailedSubmissionFormWrapper
      def permitted_params
        { title: [] }
      end
    end
  end
end
