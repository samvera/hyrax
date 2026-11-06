# frozen_string_literal: true
RSpec.describe Hyrax::Controller, type: :controller do
  controller(ApplicationController) do
    def index
      render plain: 'ok'
    end
  end

  describe '#default_url_options' do
    around do |example|
      original_locale = I18n.locale
      example.run
      I18n.locale = original_locale
    end

    context 'when the current locale is the default' do
      it 'omits :locale so URLs are not polluted with ?locale=' do
        I18n.locale = I18n.default_locale
        expect(controller.default_url_options).not_to have_key(:locale)
      end
    end

    context 'when the current locale differs from the default' do
      it 'includes :locale to preserve user locale across requests' do
        non_default = (I18n.available_locales - [I18n.default_locale]).first
        skip 'no non-default locale available' if non_default.nil?

        I18n.locale = non_default
        expect(controller.default_url_options[:locale]).to eq(non_default)
      end
    end
  end
end
