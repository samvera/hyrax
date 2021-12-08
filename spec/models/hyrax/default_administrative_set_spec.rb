# frozen_string_literal: true
RSpec.describe Hyrax::DefaultAdministrativeSet, type: :model do
  describe '.update' do
    context 'when a default already exists' do
      let!(:existing_default) { FactoryBot.create(:stored_default_admin_set_id) }
      let(:new_default_id) { '123' }
      it 'updates the saved id to the new default' do
        expect(described_class.first.default_admin_set_id).to eq existing_default.default_admin_set_id
        described_class.update(default_admin_set_id: new_default_id)
        expect(described_class.first.default_admin_set_id).to eq new_default_id
      end
    end

    context "when a default doesn't exist" do
      let(:new_default_id) { '234' }
      it 'saves the new default' do
        expect(described_class&.first&.default_admin_set_id).to be_nil
        described_class.update(default_admin_set_id: new_default_id)
        expect(described_class.first.default_admin_set_id).to eq new_default_id
      end
    end
  end

  describe 'save_supported?' do
    context 'when table exists' do
      before do
        allow(ActiveRecord::Base.connection)
          .to receive(:table_exists?)
          .with(described_class.table_name)
          .and_return(true)
      end
      it 'returns true' do
        expect(described_class.save_supported?).to eq true
      end
    end

    context 'when table does not exist' do
      before do
        allow(ActiveRecord::Base.connection)
          .to receive(:table_exists?)
          .with(described_class.table_name)
          .and_return(false)
      end
      it 'returns false' do
        expect(described_class.save_supported?).to eq false
      end
    end
  end
end
