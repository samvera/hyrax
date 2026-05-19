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

  describe '.find_row' do
    let(:path) { '/handle/12345/678' }

    it 'returns the row when one matches' do
      row = Hyrax::RedirectPath.create!(path: path, resource_id: 'res-1')
      expect(described_class.find_row(path)).to eq(row)
    end

    it 'returns nil when no row matches' do
      expect(described_class.find_row(path)).to be_nil
    end

    it 'returns nil for a blank path' do
      expect(Hyrax::RedirectPath).not_to receive(:find_by)
      expect(described_class.find_row('')).to be_nil
    end
  end

  describe '.display_path_for' do
    let(:resource_id) { 'res-1' }

    it 'returns the display row path when one is flagged' do
      Hyrax::RedirectPath.create!(path: '/a', resource_id: resource_id, display_url: false)
      Hyrax::RedirectPath.create!(path: '/b', resource_id: resource_id, display_url: true)
      expect(described_class.display_path_for(resource_id)).to eq('/b')
    end

    it 'returns nil when no row is flagged display_url for the resource' do
      Hyrax::RedirectPath.create!(path: '/a', resource_id: resource_id, display_url: false)
      expect(described_class.display_path_for(resource_id)).to be_nil
    end

    it 'returns nil for a blank resource_id' do
      expect(Hyrax::RedirectPath).not_to receive(:where)
      expect(described_class.display_path_for('')).to be_nil
    end
  end
end
