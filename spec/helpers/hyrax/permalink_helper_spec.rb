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
    let(:work_presenter) { double('WorkPresenter', collection?: false) }
    let(:collection_presenter) { double('CollectionPresenter', collection?: true) }
    let(:bare_presenter) { double('BarePresenter') }

    it 'routes works through main_app' do
      expect(helper).to receive(:polymorphic_url).with([helper.main_app, work_presenter]).and_return('http://example.test/works/1')
      expect(helper.permalink_for(work_presenter)).to eq('http://example.test/works/1')
    end

    it 'routes collections through the Hyrax engine' do
      expect(helper).to receive(:polymorphic_url).with([helper.hyrax, collection_presenter]).and_return('http://example.test/collections/1')
      expect(helper.permalink_for(collection_presenter)).to eq('http://example.test/collections/1')
    end

    it 'treats presenters without a collection? method as non-collections' do
      expect(helper).to receive(:polymorphic_url).with([helper.main_app, bare_presenter]).and_return('http://example.test/x/1')
      expect(helper.permalink_for(bare_presenter)).to eq('http://example.test/x/1')
    end

    it 'strips a locale query string appended by Rails default_url_options' do
      expect(helper).to receive(:polymorphic_url)
        .with([helper.main_app, work_presenter])
        .and_return('http://example.test/concern/generic_works/abc-123?locale=en')
      expect(helper.permalink_for(work_presenter))
        .to eq('http://example.test/concern/generic_works/abc-123')
    end

    it 'strips any query string, not just locale' do
      expect(helper).to receive(:polymorphic_url)
        .with([helper.main_app, work_presenter])
        .and_return('http://example.test/concern/generic_works/abc-123?foo=bar&baz=qux')
      expect(helper.permalink_for(work_presenter))
        .to eq('http://example.test/concern/generic_works/abc-123')
    end

    it 'strips a URL fragment as well' do
      expect(helper).to receive(:polymorphic_url)
        .with([helper.main_app, work_presenter])
        .and_return('http://example.test/concern/generic_works/abc-123?locale=en#section')
      expect(helper.permalink_for(work_presenter))
        .to eq('http://example.test/concern/generic_works/abc-123')
    end
  end

  describe '#canonical_url_for' do
    let(:presenter) { double('Presenter', id: 'res-1', collection?: false) }

    context 'when redirects are inactive' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

      it 'falls back to the permalink' do
        expect(helper).to receive(:polymorphic_url)
          .with([helper.main_app, presenter])
          .and_return('http://example.test/concern/generic_works/res-1')
        expect(helper.canonical_url_for(presenter)).to eq('http://example.test/concern/generic_works/res-1')
      end
    end

    context 'when redirects are active and a display path exists' do
      before do
        allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
        allow(Hyrax::RedirectsLookup).to receive(:display_path_for).with('res-1').and_return('/robs-cat-study')
        allow(helper).to receive(:request).and_return(double('request', base_url: 'http://example.test'))
      end

      it 'returns the display URL as the canonical URL' do
        expect(helper.canonical_url_for(presenter)).to eq('http://example.test/robs-cat-study')
      end
    end

    context 'when redirects are active but no display path exists' do
      before do
        allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
        allow(Hyrax::RedirectsLookup).to receive(:display_path_for).with('res-1').and_return(nil)
      end

      it 'falls back to the permalink' do
        expect(helper).to receive(:polymorphic_url)
          .with([helper.main_app, presenter])
          .and_return('http://example.test/concern/generic_works/res-1')
        expect(helper.canonical_url_for(presenter)).to eq('http://example.test/concern/generic_works/res-1')
      end
    end
  end
end
