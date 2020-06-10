# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ApplyCollectionPermissionTemplate do
  subject(:step) { described_class.new }
  let(:work)     { build(:generic_work) }

  it 'is a success' do
    expect(step.call(work)).to be_success
  end

  context 'when collection has no template' do
    let(:collection) { double(Collection, id: 'fake_id') }

    it 'is a failure' do
      expect(step.call(work, collections: [collection])).to be_failure
    end
  end

  context 'with permission template' do
    let(:manage_groups) { ['edit_group_1', 'edit_group_2'] }
    let(:manage_users)  { create_list(:user, 2) }
    let(:view_groups)   { ['read_group_1', 'read_group_2'] }
    let(:view_users)    { create_list(:user, 2) }
    let(:collection)    { create(:collection_lw, with_permission_template: permissions) }

    let(:permissions) do
      { manage_groups: manage_groups,
        manage_users: manage_users,
        view_groups: view_groups,
        view_users: view_users }
    end

    it 'assigns edit users from template' do
      expect { step.call(work, collections: [collection]) }
        .to change { work.edit_users }
        .to include(*manage_users.map(&:user_key))
    end

    it 'assigns edit groups from template' do
      expect { step.call(work, collections: [collection]) }
        .to change { work.edit_groups }
        .to include(*manage_groups)
    end

    it 'assigns read users from template' do
      expect { step.call(work, collections: [collection]) }
        .to change { work.read_users }
        .to include(*view_users.map(&:user_key))
    end

    it 'assigns read groups from template' do
      expect { step.call(work, collections: [collection]) }
        .to change { work.read_groups }
        .to include(*view_groups)
    end
  end
end
