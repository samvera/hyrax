# frozen_string_literal: true

RSpec.describe Hyrax::Redirects::Resolver do
  let(:resource_id) { 'res-1' }

  before { Hyrax::RedirectPath.delete_all }

  context 'when the path has no row' do
    it 'returns nil' do
      expect(described_class.call('/no-such-path')).to be_nil
    end
  end

  context 'when the path is blank' do
    it 'returns nil without consulting the table' do
      expect(Hyrax::RedirectsLookup).not_to receive(:find_row)
      expect(described_class.call('')).to be_nil
    end
  end

  context 'when the row carries target_path = nil (render in place)' do
    before do
      Hyrax::RedirectPath.create!(source_path: '/robs-cat-study', target_path: nil,
                                  display_url: true, resource_id: resource_id)
    end

    it 'returns a render_path pointing at the visited path' do
      expect(described_class.call('/robs-cat-study')).to eq(render_path: '/robs-cat-study')
    end
  end

  context 'when the row carries a target_path' do
    before do
      Hyrax::RedirectPath.create!(source_path: '/handle/12345/678', target_path: '/robs-cat-study',
                                  display_url: false, resource_id: resource_id)
    end

    it 'returns a redirect_to pointing at the stored target' do
      expect(described_class.call('/handle/12345/678')).to eq(redirect_to: '/robs-cat-study')
    end
  end

  context 'when the underlying lookup raises StatementInvalid' do
    before do
      allow(Hyrax::RedirectsLookup).to receive(:find_row)
        .and_raise(ActiveRecord::StatementInvalid, 'PG::UndefinedTable')
      allow(Hyrax.logger).to receive(:warn)
    end

    it 'logs and returns nil' do
      expect(described_class.call('/anything')).to be_nil
      expect(Hyrax.logger).to have_received(:warn).with(/resolver failed/)
    end
  end
end
