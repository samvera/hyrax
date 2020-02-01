# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SetDefaultAdminSet do
  subject(:step)   { described_class.new }
  let(:work)       { build(:hyrax_work) }
  let(:change_set) { Hyrax::ChangeSet.for(work) }

  describe '#call' do
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }

    it 'is success' do
      expect(step.call(change_set)).to be_success
    end

    it 'sets the default admin_set' do
      expect { step.call(change_set) }
        .to change { change_set.admin_set_id }
        .from(nil)
        .to(admin_set_id)
    end

    context 'when the work has an admin_set' do
      let(:admin_set) { valkyrie_create(:hyrax_admin_set) }
      let(:work)      { build(:hyrax_work, admin_set_id: admin_set.id) }

      it 'is success' do
        expect(step.call(change_set)).to be_success
      end

      it 'does not change the admin_set' do
        expect { step.call(change_set) }
          .not_to change { change_set.admin_set_id }
          .from(admin_set.id)
      end
    end

    context 'with an active fedora object' do
      let(:work) { build(:generic_work) }

      it 'is success' do
        expect(step.call(work)).to be_success
      end

      it 'sets the default admin_set' do
        expect { step.call(work) }
          .to change { work.admin_set&.id }
          .from(nil)
          .to(admin_set_id)
      end

      context 'when the work has an admin_set' do
        let(:admin_set) { create(:admin_set) }
        let(:work)      { build(:generic_work, admin_set: admin_set) }

        it 'is success' do
          expect(step.call(work)).to be_success
        end

        it 'does not change the admin_set' do
          expect { step.call(work) }
            .not_to change { work.admin_set&.id }
            .from(admin_set.id)
        end
      end
    end
  end
end
