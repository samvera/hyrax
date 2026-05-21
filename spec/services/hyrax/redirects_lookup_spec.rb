# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsLookup do
  before { Hyrax::RedirectPath.delete_all }

  def existing_row(from_path:, resource_id:)
    Hyrax::RedirectPath.create!(
      from_path: from_path,
      to_path: "/concern/generic_works/#{resource_id}",
      permalink_path: "/concern/generic_works/#{resource_id}",
      resource_id: resource_id,
      is_display_url: false
    )
  end

  describe '.taken?' do
    let(:path) { '/handle/12345/678' }

    context 'when no row exists for the path' do
      it 'is false' do
        expect(described_class.taken?(path)).to be false
      end
    end

    context 'when a row exists for the path on a different resource' do
      before { existing_row(from_path: path, resource_id: 'other-record') }

      it 'is true' do
        expect(described_class.taken?(path)).to be true
      end
    end

    context 'with except_id matching the row that owns the path' do
      before { existing_row(from_path: path, resource_id: 'self-id') }

      it 'is false (the path is held by the record being edited)' do
        expect(described_class.taken?(path, except_id: 'self-id')).to be false
      end
    end

    context 'with except_id not matching the row that owns the path' do
      before { existing_row(from_path: path, resource_id: 'other-record') }

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

    context 'when a row exists with that from_path' do
      let!(:row) { existing_row(from_path: path, resource_id: 'res-1') }

      it 'returns the row' do
        expect(described_class.find_row(path)).to eq(row)
      end
    end

    context 'when no row matches' do
      it 'returns nil' do
        expect(described_class.find_row(path)).to be_nil
      end
    end

    context 'when the input needs normalization' do
      before { existing_row(from_path: '/foo', resource_id: 'res-1') }

      it 'normalizes before looking up' do
        expect(described_class.find_row('/foo/')).to be_present
        expect(described_class.find_row('http://example.com/foo')).to be_present
      end
    end

    context 'with a blank path' do
      it 'returns nil without consulting the table' do
        expect(Hyrax::RedirectPath).not_to receive(:find_by)
        expect(described_class.find_row('')).to be_nil
        expect(described_class.find_row(nil)).to be_nil
      end
    end
  end
end
