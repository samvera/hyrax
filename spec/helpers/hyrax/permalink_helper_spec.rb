# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::PermalinkHelper, type: :helper do
  describe '#copy_permalink_enabled?' do
    context 'when the Flipflop feature is enabled' do
      before { allow(Flipflop).to receive(:enabled?).with(:copy_permalink_button).and_return(true) }
      it { expect(helper.copy_permalink_enabled?).to be true }
    end

    context 'when the Flipflop feature is disabled' do
      before { allow(Flipflop).to receive(:enabled?).with(:copy_permalink_button).and_return(false) }
      it { expect(helper.copy_permalink_enabled?).to be false }
    end
  end

  describe '#permalink_for' do
    let(:presenter) { double('Presenter') }

    before do
      allow(helper.request).to receive(:base_url).and_return('http://example.test')
    end

    it 'concatenates request.base_url with the canonical path from Hyrax::PermalinkPath' do
      allow(Hyrax::PermalinkPath).to receive(:call).with(presenter).and_return('/concern/generic_works/abc-123')
      expect(helper.permalink_for(presenter)).to eq('http://example.test/concern/generic_works/abc-123')
    end

    it 'strips a locale query string appended by Rails default_url_options' do
      allow(Hyrax::PermalinkPath).to receive(:call).with(presenter).and_return('/concern/generic_works/abc-123?locale=en')
      expect(helper.permalink_for(presenter)).to eq('http://example.test/concern/generic_works/abc-123')
    end

    it 'strips any query string, not just locale' do
      allow(Hyrax::PermalinkPath).to receive(:call).with(presenter).and_return('/concern/generic_works/abc-123?foo=bar&baz=qux')
      expect(helper.permalink_for(presenter)).to eq('http://example.test/concern/generic_works/abc-123')
    end

    it 'strips a URL fragment as well' do
      allow(Hyrax::PermalinkPath).to receive(:call).with(presenter).and_return('/concern/generic_works/abc-123#section')
      expect(helper.permalink_for(presenter)).to eq('http://example.test/concern/generic_works/abc-123')
    end
  end

  describe '#canonical_url_for' do
    let(:presenter) { double('Presenter', id: 'abc-123') }

    before do
      allow(helper.request).to receive(:base_url).and_return('http://example.test')
      allow(Hyrax::PermalinkPath).to receive(:call).with(presenter).and_return('/concern/generic_works/abc-123')
    end

    context 'when redirects are inactive' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

      it 'returns the UUID permalink without querying the redirects table' do
        expect(Hyrax::RedirectsLookup).not_to receive(:display_path_for)
        expect(helper.canonical_url_for(presenter)).to eq('http://example.test/concern/generic_works/abc-123')
      end
    end

    context 'when redirects are active but the record has no display URL row' do
      before do
        allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
        allow(Hyrax::RedirectsLookup).to receive(:display_path_for).with('abc-123').and_return(nil)
      end

      it 'falls back to the UUID permalink' do
        expect(helper.canonical_url_for(presenter)).to eq('http://example.test/concern/generic_works/abc-123')
      end
    end

    context 'when redirects are active and the record has a display URL row' do
      before do
        allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
        allow(Hyrax::RedirectsLookup).to receive(:display_path_for).with('abc-123').and_return('/preferred')
      end

      it 'returns the display alias as an absolute URL' do
        expect(helper.canonical_url_for(presenter)).to eq('http://example.test/preferred')
      end

      it 'strips any query string from the resulting URL' do
        allow(Hyrax::RedirectsLookup).to receive(:display_path_for).with('abc-123').and_return('/preferred?locale=en')
        expect(helper.canonical_url_for(presenter)).to eq('http://example.test/preferred')
      end
    end
  end
end
