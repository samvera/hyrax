# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsLookup do
  before { Hyrax::RedirectPath.delete_all }

  describe '.taken?' do
    let(:path) { '/handle/12345/678' }

    context 'when no row exists for the path' do
      it 'is false' do
        expect(described_class.taken?(path)).to be false
      end
    end

    context 'when a row exists for the path on a different resource' do
      before { Hyrax::RedirectPath.create!(path: path, resource_id: 'other-record') }

      it 'is true' do
        expect(described_class.taken?(path)).to be true
      end
    end

    context 'with except_id matching the row that owns the path' do
      before { Hyrax::RedirectPath.create!(path: path, resource_id: 'self-id') }

      it 'is false (the path is held by the record being edited)' do
        expect(described_class.taken?(path, except_id: 'self-id')).to be false
      end
    end

    context 'with except_id not matching the row that owns the path' do
      before { Hyrax::RedirectPath.create!(path: path, resource_id: 'other-record') }

      it 'is true' do
        expect(described_class.taken?(path, except_id: 'self-id')).to be true
      end
    end

    context 'with a blank path' do
      it 'is false without consulting the table' do
        expect(Hyrax::RedirectPath).not_to receive(:where)
        expect(described_class.taken?('')).to be false
      end
    end
  end
end
