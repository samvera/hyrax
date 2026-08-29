# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::TrophyCleanupListener do
  subject(:listener) { described_class.new }

  describe '#on_object_deleted' do
    let(:user)         { FactoryBot.create(:user) }
    let(:event)        { Dry::Events::Event.new(:on_object_deleted, data) }
    let(:target_id)    { data[:object]&.id || data[:id] }

    before do
      Trophy.where(work_id: [target_id, 'other-work']).delete_all
      Trophy.create(user_id: user.id, work_id: target_id)
      Trophy.create(user_id: user.id + 1, work_id: 'other-work')
    end

    context 'when the deleted event includes only an id' do
      let(:data) { { id: 'z890s9938', user: user } }

      it 'deletes matching trophies without raising' do
        expect { listener.on_object_deleted(event) }
          .to change { Trophy.where(work_id: target_id).count }
          .from(1).to(0)

        expect(Trophy.where(work_id: 'other-work').count).to eq(1)
      end
    end

    context 'when the deleted event includes an object' do
      let(:data) { { object: instance_double('resource', id: 'z890s9938'), user: user } }

      it 'deletes matching trophies' do
        expect { listener.on_object_deleted(event) }
          .to change { Trophy.where(work_id: target_id).count }
          .from(1).to(0)
      end
    end
  end
end
