# frozen_string_literal: true
RSpec.describe Hyrax::PermissionTemplate, :clean_repo do
  subject(:permission_template) { described_class.new(attributes) }

  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:collection) { FactoryBot.create(:collection) }
  let(:attributes) { { source_id: admin_set.id } }

  it { is_expected.to have_many(:available_workflows).dependent(:destroy) }
  it { is_expected.to have_one(:active_workflow).conditions(active: true).dependent(nil) }
  it { is_expected.to have_many(:access_grants).dependent(:destroy) }

  describe '#agent_ids_for' do
    it 'queries the underlying access_grants' do
      template = create(:permission_template)
      to_find = template.access_grants.create!(agent_type: 'user', access: 'manage', agent_id: '123')
      template.access_grants.create!(agent_type: 'user', access: 'view', agent_id: '456')
      template.access_grants.create!(agent_type: 'group', access: 'manage', agent_id: '789')

      expect(template.agent_ids_for(agent_type: 'user', access: 'manage')).to eq([to_find.agent_id])
    end
  end

  describe "#source_model" do
    context 'when source is an AdminSet' do
      let(:as_permission_template) { described_class.new(as_attributes) }
      let(:as_attributes) { { source_id: admin_set.id } }

      before do
        allow(AdminSet).to receive(:find).with(as_permission_template.source_id).and_return(admin_set)
      end

      it 'returns an AdminSet if the source_type is admin_set for the given permission_template' do
        expect(as_permission_template.source_model).to be_kind_of(AdminSet)
        expect(as_permission_template.source_model).to eq(admin_set)
      end
    end

    context 'when source is a Collection' do
      let(:col_permission_template) { described_class.new(col_attributes) }
      let(:col_attributes) { { source_id: collection.id } }

      before do
        allow(Collection).to receive(:find).with(col_permission_template.source_id).and_return(collection)
      end

      it 'returns a Collection if the source_type is collection for the given permission_template' do
        expect(col_permission_template.source_model).to be_kind_of(Collection)
        expect(col_permission_template.source_model).to eq(collection)
      end
    end
  end

  describe "#release_fixed_date?" do
    subject { permission_template.release_fixed_date? }

    context "with release_period='fixed'" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { is_expected.to be false }
    end
  end

  describe "#release_no_delay?" do
    subject { permission_template.release_no_delay? }

    context "with release_period='now'" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.to be false }
    end
  end

  describe "#release_before_date?" do
    subject { permission_template.release_before_date? }

    context "with release_period='before'" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE } }

      it { is_expected.to be true }
    end
    context "with maximum embargo period (release_period of 1 year)" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }

      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.to be false }
    end
  end

  describe "#release_max_embargo?" do
    subject { permission_template.release_max_embargo? }

    context "with release_period of 1 year" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }

      it { is_expected.to be true }
    end
    context "with release_period of 2 years" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS } }

      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }

      it { is_expected.to be false }
    end
  end

  describe "#release_date" do
    subject { permission_template.release_date }

    let(:today) { Time.zone.today }

    context "with today and release_fixed_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: today } }

      it { is_expected.to eq today }
    end
    context "with today and release_before_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today } }

      it { is_expected.to eq today }
    end
    context "with release_period of 6 months" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS } }

      it { is_expected.to eq today + 6.months }
    end
    context "with release_period of 1 year" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }

      it { is_expected.to eq today + 1.year }
    end
    context "with release_no_delay?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { is_expected.to eq today }
    end
  end

  describe "#valid_release_date?" do
    let(:date) { Time.zone.today + 6.months }

    subject { permission_template.valid_release_date?(date) }

    context "with any release date and one is not required" do
      let(:attributes) { { source_id: admin_set.id } }

      it { is_expected.to eq true }
    end
    context "with matching date and release_fixed_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: date } }

      it { is_expected.to eq true }
    end
    context "with non-matching date and release_fixed_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: date + 1.day } }

      it { is_expected.to eq false }
    end
    context "with exact match date and release_before_date?" do
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: date } }

      it { is_expected.to eq true }
    end
    context "with future, valid date and release_before_date?" do
      let(:date) { Time.zone.today + 1.day }
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: Time.zone.today + 1.month } }

      it { is_expected.to eq true }
    end
    context "with future, invalid date and release_before_date?" do
      let(:date) { Time.zone.today + 1.year }
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: Time.zone.today + 1.month } }

      it { is_expected.to eq false }
    end
    context "with today release and release_no_delay?" do
      let(:date) { Time.zone.today }
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { is_expected.to eq true }
    end
    context "with tomorrow release and release_no_delay?" do
      let(:date) { Time.zone.today + 1.day }
      let(:attributes) { { source_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }

      it { is_expected.to eq false }
    end
  end

  describe "#valid_visibility?" do
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

    subject { permission_template.valid_visibility?(visibility) }

    context "with matching visibility" do
      let(:attributes) { { source_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

      it { is_expected.to eq true }
    end
    context "with non-matching visibility" do
      let(:attributes) { { source_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED } }

      it { is_expected.to eq false }
    end
    context "with visibility when none required" do
      let(:attributes) { { source_id: admin_set.id } }

      it { is_expected.to eq true }
    end
  end
end
