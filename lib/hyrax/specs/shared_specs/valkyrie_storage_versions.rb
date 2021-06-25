# frozen_string_literal: true

RSpec.shared_examples 'a Valkyrie::StorageAdapter with versioning support' do
  describe '#supports?' do
    it 'supports versions' do
      expect(storage_adapter.supports?(:versions)).to eq true
    end
  end
end
