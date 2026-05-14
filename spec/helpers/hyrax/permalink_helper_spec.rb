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
  end
end
