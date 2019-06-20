# frozen_string_literal: true
require 'valkyrie/indexing_adapter'

RSpec.describe Valkyrie::IndexingAdapter do
  let(:adapter) do
    Class.new { ; }
  end

  describe ".register" do
    it "registers an adapter to a short name" do
      described_class.register adapter, :test_adapter

      expect(described_class.find(:test_adapter)).to eq adapter
    end
  end

  describe '.find' do
    subject(:find) { described_class.find(:huh?) }
    context 'when no adapter is registered' do
      it 'raises an error' do
        expect { find }.to raise_error "Unable to find unregistered adapter `huh?'"
      end
    end
  end
end
