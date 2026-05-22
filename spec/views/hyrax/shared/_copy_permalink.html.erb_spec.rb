# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hyrax/shared/_copy_permalink.html.erb', type: :view do
  let(:presenter) { double('Presenter') }

  before do
    allow(view).to receive(:permalink_for).with(presenter).and_return('http://example.test/concern/generic_works/abc-123')
  end

  context 'when the copy_permalink_button feature is enabled' do
    before { allow(view).to receive(:copy_permalink_enabled?).and_return(true) }

    it 'renders a button with the canonical URL as data-clipboard-text' do
      render partial: 'hyrax/shared/copy_permalink', locals: { presenter: presenter }
      expect(rendered).to have_css(
        'button.copy-permalink-button[data-clipboard-text="http://example.test/concern/generic_works/abc-123"]'
      )
    end

    it 'renders the button label from the locale' do
      render partial: 'hyrax/shared/copy_permalink', locals: { presenter: presenter }
      expect(rendered).to include(I18n.t('hyrax.copy_permalink.button'))
    end

    # The button's initial `title` is the button label, not the success text.
    # Before the Bootstrap tooltip is initialized (or if JS doesn't run), the
    # browser falls back to the native title-attribute tooltip on hover. If we
    # left "Copied!" in the title, a pre-click hover would misleadingly suggest
    # the copy already happened. The success text lives in a separate
    # data-success-text attribute that the JS swaps in only after a copy.
    it 'uses the button label (not the success text) as the initial title' do
      render partial: 'hyrax/shared/copy_permalink', locals: { presenter: presenter }
      expect(rendered).to have_css(
        "button.copy-permalink-button[title=\"#{I18n.t('hyrax.copy_permalink.button')}\"]"
      )
    end

    it 'carries the success text in a data-success-text attribute' do
      render partial: 'hyrax/shared/copy_permalink', locals: { presenter: presenter }
      expect(rendered).to have_css(
        "button.copy-permalink-button[data-success-text=\"#{I18n.t('hyrax.copy_permalink.success')}\"]"
      )
    end
  end

  context 'when the copy_permalink_button feature is disabled' do
    before { allow(view).to receive(:copy_permalink_enabled?).and_return(false) }

    it 'renders nothing' do
      render partial: 'hyrax/shared/copy_permalink', locals: { presenter: presenter }
      expect(rendered.strip).to be_empty
    end
  end
end
