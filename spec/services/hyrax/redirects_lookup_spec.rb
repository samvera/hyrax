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
      before { Hyrax::RedirectPath.create!(source_path: path, target_path: path, resource_id: 'other-record') }

      it 'is true' do
        expect(described_class.taken?(path)).to be true
      end
    end

    context 'with except_id matching the row that owns the path' do
      before { Hyrax::RedirectPath.create!(source_path: path, target_path: path, resource_id: 'self-id') }

      it 'is false (the path is held by the record being edited)' do
        expect(described_class.taken?(path, except_id: 'self-id')).to be false
      end
    end

    context 'with except_id not matching the row that owns the path' do
      before { Hyrax::RedirectPath.create!(source_path: path, target_path: path, resource_id: 'other-record') }

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

  describe '.find_by_source_path' do
    let(:path) { '/handle/12345/678' }

    context 'when no row exists for the path' do
      it 'is nil' do
        expect(described_class.find_by_source_path(path)).to be_nil
      end
    end

    context 'when a row exists for the path' do
      let!(:row) do
        Hyrax::RedirectPath.create!(source_path: path,
                                    target_path: '/concern/generic_works/abc-123',
                                    resource_id: 'abc-123')
      end

      it 'returns the row' do
        result = described_class.find_by_source_path(path)
        expect(result).to eq(row)
        expect(result.target_path).to eq('/concern/generic_works/abc-123')
        expect(result.resource_id).to eq('abc-123')
      end
    end

    context 'with a non-normalized input form' do
      let!(:row) do
        Hyrax::RedirectPath.create!(source_path: '/handle/12345/678',
                                    target_path: '/concern/generic_works/abc-123',
                                    resource_id: 'abc-123')
      end

      it 'normalizes the input before looking up' do
        expect(described_class.find_by_source_path('/handle/12345/678/')).to eq(row)
      end
    end

    context 'with a blank path' do
      it 'is nil without consulting the table' do
        expect(Hyrax::RedirectPath).not_to receive(:find_by)
        expect(described_class.find_by_source_path('')).to be_nil
      end
    end
  end
end
