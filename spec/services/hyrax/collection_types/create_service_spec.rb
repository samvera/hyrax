# frozen_string_literal: true
RSpec.describe Hyrax::CollectionTypes::CreateService do
  describe '.create_collection_type' do
    it 'create collection type with default options when no options are received' do # rubocop:disable RSpec/ExampleLength
      described_class.create_collection_type(machine_id: 'custom_type', title: 'Custom Type')
      ct = Hyrax::CollectionType.find_by_machine_id('custom_type')
      expect(ct.machine_id).to eq('custom_type')
      expect(ct.title).to eq('Custom Type')
      expect(ct.description).to eq('')
      expect(ct.badge_color).to eq('#663333')
      expect(ct).to be_nestable
      expect(ct).to be_discoverable
      expect(ct).to be_brandable
      expect(ct).to be_sharable
      expect(ct).to be_share_applies_to_new_works
      expect(ct).to be_allow_multiple_membership
      expect(ct).not_to be_require_membership
      expect(ct).not_to be_assigns_workflow
      expect(ct).not_to be_assigns_visibility
    end

    it 'creates a collection type for the options received' do
      options = { description: 'A collection type with options.',
                  badge_color: '#ffa510',
                  discoverable: false }
      described_class.create_collection_type(machine_id: 'custom_type', title: 'Custom Type', options: options)
      ct = Hyrax::CollectionType.find_by_machine_id('custom_type')
      expect(ct.description).to include('with options')
      expect(ct.badge_color).to include('#ffa510')
      expect(ct).not_to be_discoverable
    end

    it 'creates collection participants defined in options' do
      expect do
        described_class.create_collection_type(machine_id: 'custom_type', title: 'Custom Type')
      end.to change(Hyrax::CollectionTypeParticipant, :count).by(described_class::DEFAULT_OPTIONS[:participants].count)
    end
  end

  describe '.create_admin_set_type' do
    it 'create the admin set type' do # rubocop:disable RSpec/ExampleLength
      described_class.create_admin_set_type
      ct = Hyrax::CollectionType.find_by_machine_id(Hyrax::CollectionType::ADMIN_SET_MACHINE_ID)
      expect(ct.machine_id).to eq(Hyrax::CollectionType::ADMIN_SET_MACHINE_ID)
      expect(ct.title).to eq(Hyrax::CollectionType::ADMIN_SET_DEFAULT_TITLE)
      expect(ct.description).to eq('An aggregation of works that is intended to help with administrative control. Admin Sets provide a way of defining behaviors and policies around a set of works.')
      expect(ct.badge_color).to eq('#405060')
      expect(ct).not_to be_nestable
      expect(ct).not_to be_brandable
      expect(ct).not_to be_discoverable
      expect(ct).to be_sharable
      expect(ct).to be_share_applies_to_new_works
      expect(ct).not_to be_allow_multiple_membership
      expect(ct).to be_require_membership
      expect(ct).to be_assigns_workflow
      expect(ct).to be_assigns_visibility
    end
  end

  describe '.create_user_collection_type' do
    it 'create the user collection type' do # rubocop:disable RSpec/ExampleLength
      described_class.create_user_collection_type
      ct = Hyrax::CollectionType.find_by_machine_id(Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID)
      expect(ct.machine_id).to eq(Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID)
      expect(ct.title).to eq(Hyrax::CollectionType::USER_COLLECTION_DEFAULT_TITLE)
      expect(ct.description).to eq('A User Collection can be created by any user to organize their works.')
      expect(ct.badge_color).to eq('#705070')
      expect(ct).to be_nestable
      expect(ct).to be_brandable
      expect(ct).to be_discoverable
      expect(ct).to be_sharable
      expect(ct).not_to be_share_applies_to_new_works
      expect(ct).to be_allow_multiple_membership
      expect(ct).not_to be_require_membership
      expect(ct).not_to be_assigns_workflow
      expect(ct).not_to be_assigns_visibility
    end
  end

  describe '.add_default_participants' do
    let(:coltype) { create(:collection_type) }

    it 'adds the default participants to a collection type' do
      expect(Hyrax::CollectionTypeParticipant).to receive(:create!).exactly(2).times
      described_class.add_default_participants(coltype.id)
    end
  end

  describe '.add_participants' do
    let(:participants) { [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: 'test_group', access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }] }
    let(:coltype) { create(:collection_type) }

    it 'adds the participants to a collection type' do
      expect { described_class.add_participants(coltype.id, participants) }
        .to change { Hyrax::CollectionType.find(coltype.id).collection_type_participants.to_a }
        .to contain_exactly an_object_having_attributes(**participants.first)
    end

    context 'when participants are incomplete' do
      let(:participants) do
        [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
           agent_id: 'test_group',
           access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
         { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
           agent_id: 'test_group' }]
      end

      it 'logs and raises an error' do
        expect(Hyrax.logger)
          .to receive(:error)
          .with a_string_starting_with('Participants not created')

        expect { described_class.add_participants(coltype.id, participants) }
          .to raise_error(described_class::InvalidParticipantError)
      end

      it 'does not add participants' do
        expect do
          described_class.add_participants(coltype.id, participants)
        rescue described_class::InvalidParticipantError
          nil
        end.not_to change { Hyrax::CollectionType.find(coltype.id).collection_type_participants.to_a }
      end
    end
  end
end
