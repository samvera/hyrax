module Sipity
  RSpec.describe Role, type: :model do
    context 'class methods' do
      subject { described_class }

      its(:column_names) { is_expected.to include('name') }
      its(:column_names) { is_expected.to include('description') }
      context '.[]' do
        let(:valid_name) { 'reviewing' }

        it 'will find the named role' do
          expected_object = described_class.create!(name: valid_name)
          expect(described_class[valid_name]).to eq(expected_object)
        end

        it 'will created the named role' do
          expect { described_class[valid_name].name }.to change { described_class.count }.by(1)
        end
      end
    end

    subject { described_class.new }

    it 'will have a #to_s that is a name' do
      subject.name = 'advising'
      expect(subject.to_s).to eq(subject.name)
    end

    context '#destroy' do
      it 'will not allow registered role names to be destroyed' do
        role = Sipity::Role.create!(name: Hyrax::RoleRegistry::MANAGING)
        expect { role.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
      it 'will allow unregistered role names to be destroyed' do
        role = Sipity::Role.create!(name: 'gong_farming')
        expect { role.destroy! }.not_to raise_error
      end
    end
  end
end
