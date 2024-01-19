# frozen_string_literal: true
RSpec.describe Hyrax::PermissionTemplate, valkyrie_adapter: :test_adapter do
  subject(:permission_template) { described_class.new(attributes) }
  let(:attributes) { { source_id: admin_set.id } }
  let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

  it { is_expected.to have_many(:available_workflows).dependent(:destroy) }
  it { is_expected.to have_one(:active_workflow).conditions(active: true).dependent(nil) }
  it { is_expected.to have_many(:access_grants).dependent(:destroy) }

  describe '#agent_ids_for' do
    subject(:permission_template) { FactoryBot.create(:permission_template) }

    before do
      permission_template.access_grants.create!(agent_type: 'user', access: 'manage', agent_id: '123')
      permission_template.access_grants.create!(agent_type: 'user', access: 'manage', agent_id: 'abc')
      permission_template.access_grants.create!(agent_type: 'user', access: 'view', agent_id: '456')
      permission_template.access_grants.create!(agent_type: 'group', access: 'manage', agent_id: '789')
    end

    it 'queries the underlying access_grants' do
      expect(permission_template.agent_ids_for(agent_type: 'user', access: 'manage'))
        .to contain_exactly('123', 'abc')
      expect(permission_template.agent_ids_for(agent_type: 'user', access: 'view'))
        .to contain_exactly('456')
      expect(permission_template.agent_ids_for(agent_type: 'group', access: 'manage'))
        .to contain_exactly('789')
    end
  end

  describe "#source" do
    context 'when source is an AdminSet' do
      it 'returns the source admin set' do
        expect(permission_template.source).to eq admin_set
      end
    end

    context 'when source is a Collection' do
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }
      let(:attributes) { { source_id: collection.id } }

      it 'returns a Hyrax::PcdmCollection' do
        expect(permission_template.source).to eq collection
      end
    end

    context 'when source is any Resource' do
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_resource) }

      it 'returns the source model' do
        expect(permission_template.source).to eq admin_set
      end
    end
  end

  describe "#source_model", valkyrie_adapter: :wings_adapter do
    context 'when source is an AdminSet' do
      let(:admin_set) { FactoryBot.create(:admin_set) }
      let(:attributes) { { source_id: admin_set.id } }

      it 'returns an AdminSet if the source_type is admin_set for the given permission_template' do
        expect(permission_template.source_model).to eq(admin_set)
      end
    end

    context 'when source is a Collection' do
      let(:collection) { FactoryBot.create(:collection) }
      let(:attributes) { { source_id: collection.id } }

      it 'returns a Collection if the source_type is collection for the given permission_template' do
        expect(permission_template.source_model).to eq(collection)
      end
    end
  end

  describe "#reset_access_controls_for" do
    subject(:permission_template) { FactoryBot.create(:permission_template) }

    let(:read_user) { FactoryBot.create(:user) }

    before do
      permission_template.access_grants.create!(agent_type: 'user', access: 'view', agent_id: read_user.user_key)
      permission_template.access_grants.create!(agent_type: 'group', access: 'manage', agent_id: '789')
    end

    context "with a Valkyrie based collection" do
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, :public) }

      it "sets access controls to template settings" do
        expect { permission_template.reset_access_controls_for(collection: collection) }
          .to change { Hyrax::AccessControlList.new(resource: collection).permissions }
          .to contain_exactly(have_attributes(mode: :read, agent: read_user.user_key),
                              have_attributes(mode: :edit, agent: 'group/789'))
      end

      it "retains visibility when asked" do
        expect { permission_template.reset_access_controls_for(collection: collection, interpret_visibility: true) }
          .to change { Hyrax::AccessControlList.new(resource: collection).permissions }
          .to contain_exactly(have_attributes(mode: :read, agent: read_user.user_key),
                              have_attributes(mode: :edit, agent: 'group/789'),
                              have_attributes(mode: :read, agent: 'group/public'))
      end
    end

    context "with an ActiveFedora ::Collection", :active_fedora do
      let(:collection) { FactoryBot.create(:collection) }

      it "sets access controls to template settings" do
        expect { permission_template.reset_access_controls_for(collection: collection) }
          .to change { collection.edit_groups }
          .to contain_exactly('789')
      end

      it "does not apply collection visibility by default" do
        collection.visibility = "open"

        expect { permission_template.reset_access_controls_for(collection: collection) }
          .to change { collection.read_groups }
          .from(contain_exactly('public'))
          .to be_empty
      end

      it "applies collection visibility when asked" do
        collection.visibility = "open"

        expect { permission_template.reset_access_controls_for(collection: collection, interpret_visibility: true) }
          .not_to change { collection.read_groups }
      end
    end
  end

  describe "#release_fixed_date?" do
    context "with release_period='fixed'" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.to be_release_fixed_date }
    end

    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { is_expected.not_to be_release_fixed_date }
    end
  end

  describe "#release_no_delay?" do
    context "with release_period='now'" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { is_expected.to be_release_no_delay }
    end

    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.not_to be_release_no_delay }
    end
  end

  describe "#release_before_date?" do
    context "with release_period='before'" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE } }

      it { is_expected.to be_release_before_date }
    end

    context "with maximum embargo period (release_period of 1 year)" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }

      it { is_expected.to be_release_before_date }
    end

    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.not_to be_release_before_date }
    end
  end

  describe "#release_max_embargo?" do
    context "with release_period of 1 year" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }

      it { is_expected.to be_release_max_embargo }
    end

    context "with release_period of 2 years" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS } }

      it { is_expected.to be_release_max_embargo }
    end

    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.not_to be_release_max_embargo }
    end
  end

  describe "#release_date" do
    context "with today and release_fixed_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: Time.zone.today } }

      its(:release_date) { is_expected.to eq Time.zone.today }
    end

    context "with today and release_before_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: Time.zone.today } }

      its(:release_date) { is_expected.to eq Time.zone.today }
    end

    context "with release_period of 6 months" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS } }

      its(:release_date) { is_expected.to eq Time.zone.today + 6.months }
    end

    context "with release_period of 1 year" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }

      its(:release_date) { is_expected.to eq Time.zone.today + 1.year }
    end

    context "with release_no_delay?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      its(:release_date) { is_expected.to eq Time.zone.today }
    end
  end

  describe "#valid_release_date?" do
    let(:date) { Time.zone.today + 6.months }

    context "with any release date and one is not required" do
      let(:attributes) { { source_id: admin_set.id } }

      it { expect(permission_template.valid_release_date?(date)).to eq true }
    end

    context "with matching date and release_fixed_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: date } }

      it { expect(permission_template.valid_release_date?(date)).to eq true }
    end

    context "with non-matching date and release_fixed_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: date + 1.day } }

      it { expect(permission_template.valid_release_date?(date)).to eq false }
    end

    context "with exact match date and release_before_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: date } }

      it { expect(permission_template.valid_release_date?(date)).to eq true }
    end

    context "with future, valid date and release_before_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: Time.zone.today + 1.month } }

      it { expect(permission_template.valid_release_date?(Time.zone.today + 1.day)).to eq true }
    end

    context "with future, invalid date and release_before_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: Time.zone.today + 1.month } }

      it { expect(permission_template.valid_release_date?(Time.zone.today + 1.year)).to eq false }
    end

    context "with today release and release_no_delay?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { expect(permission_template.valid_release_date?(Time.zone.today)).to eq true }
    end

    context "with tomorrow release and release_no_delay?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { expect(permission_template.valid_release_date?(Time.zone.today + 1.day)).to eq false }
    end
  end

  describe "#valid_visibility?" do
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

    context "with matching visibility" do
      let(:attributes) { { source_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

      it { expect(permission_template.valid_visibility?(visibility)).to eq true }
    end

    context "with non-matching visibility" do
      let(:attributes) { { source_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED } }

      it { expect(permission_template.valid_visibility?(visibility)).to eq false }
    end

    context "with visibility when none required" do
      let(:attributes) { { source_id: admin_set.id } }

      it { expect(permission_template.valid_visibility?(visibility)).to eq true }
    end
  end
end
