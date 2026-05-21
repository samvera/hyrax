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
end
