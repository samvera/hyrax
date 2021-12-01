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
end
