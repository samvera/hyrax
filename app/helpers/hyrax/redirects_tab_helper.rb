# frozen_string_literal: true

module Hyrax
  ##
  # Decides whether the Aliases tab should appear on a work or
  # collection edit form. Included into `WorkFormHelper` and
  # `CollectionsHelper` so both forms share one rule.
  #
  # The tab appears only when the redirects feature is fully active
  # (`Hyrax.config.redirects_active?`), the form is a ResourceForm
  # (the only form pipeline with the redirects populator, validator,
  # and prepopulator wired in), AND the form's underlying resource
  # carries the `redirects` attribute. The structural check guards
  # against adopter work or collection classes that don't include
  # the redirects schema; without it the tab would render and crash
  # on `f.object.redirects`.
  module RedirectsTabHelper
    def redirects_tab?(form)
      return false unless Hyrax.config.redirects_active?
      return false unless redirects_supported_form?(form)
      target = form.respond_to?(:model) ? form.model : form
      target.respond_to?(:redirects)
    end

    def redirects_supported_form?(form)
      form.is_a?(Hyrax::Forms::ResourceForm)
    end
  end
end
