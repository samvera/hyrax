# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::CreateWork do
  subject(:transaction) { described_class.new }
  let(:work)            { build(:generic_work) }
  let(:xmas)            { DateTime.parse('2018-12-25 11:30').iso8601 }

  before do
    Hyrax::PermissionTemplate
      .find_or_create_by(source_id: AdminSet.find_or_create_default_admin_set_id)
  end

  describe '#call' do
    context 'with an invalid work' do
      let(:work) { build(:invalid_generic_work) }

      it 'is a failure' do
        expect(transaction.call(work)).to be_failure
      end

      it 'does not save the work' do
        expect { transaction.call(work) }.not_to change { work.new_record? }.from true
      end
    end

    it 'is a success' do
      expect(transaction.call(work)).to be_success
    end

    it 'persists the work' do
      expect { transaction.call(work) }
        .to change { work.persisted? }
        .to true
    end

    it 'sets visibility to restricted by default' do
      expect { transaction.call(work) }
        .not_to change { work.visibility }
        .from Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    it 'sets the default admin set' do
      expect { transaction.call(work) }
        .to change { work.admin_set&.id }
        .to AdminSet.find_or_create_default_admin_set_id
    end

    it 'sets the modified time using Hyrax::TimeService' do
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas)

      expect { transaction.call(work) }.to change { work.date_modified }.to xmas
    end

    it 'sets the created time using Hyrax::TimeService' do
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas)

      expect { transaction.call(work) }.to change { work.date_uploaded }.to xmas
    end
  end

  context 'with an admin set' do
    let(:admin_set) { create(:admin_set, with_permission_template: true) }
    let(:work)      { build(:generic_work, admin_set: admin_set) }

    context 'without a permission template' do
      let(:admin_set) { create(:admin_set, with_permission_template: false) }

      it 'is a failure' do
        expect(transaction.call(work)).to be_failure
      end

      it 'is does not persist the work' do
        expect { transaction.call(work) }
          .not_to change { work.persisted? }
          .from false
      end
    end

    it 'is a success' do
      expect(transaction.call(work)).to be_success
    end

    it 'retains the set admin set' do
      expect { transaction.call(work) }
        .not_to change { work.admin_set&.id }
        .from admin_set.id
    end
  end
end
