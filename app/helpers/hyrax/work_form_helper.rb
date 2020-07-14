# frozen_string_literal: true
module Hyrax
  module WorkFormHelper
    def form_tabs_for(form:)
      if form.instance_of? Hyrax::Forms::BatchUploadForm
        %w[files metadata relationships]
      else
        %w[metadata files relationships]
      end
    end
  end
end
