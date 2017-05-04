describe Hyrax::PermissionTemplate do
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { described_class.new(attributes) }
  let(:attributes) { { admin_set_id: admin_set.id } }

  subject { permission_template }
  it { is_expected.to have_many(:available_workflows).dependent(:destroy) }
  it { is_expected.to have_one(:active_workflow).conditions(active: true).dependent(nil) }
  it { is_expected.to have_many(:access_grants).dependent(:destroy) }

  describe 'factories' do
    context 'with_admin_set parameter' do
      it 'will create an AdminSet when true' do
        permission_template = create(:permission_template, with_admin_set: true)
        expect(permission_template.admin_set).to be_persisted
      end
      it 'will not persist an AdminSet when false (or not given)' do
        permission_template = create(:permission_template, with_admin_set: false)
        expect { permission_template.admin_set }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end

    context 'with_workflows parameter' do
      it 'will create the workflow when set true' do
        expect { create(:permission_template, with_workflows: true) }.to change { Sipity::Workflow.count }
      end
      it 'will not create the workflow when false (or not given)' do
        expect { create(:permission_template, with_workflows: false) }.not_to change { Sipity::Workflow.count }
      end
    end

    context 'with_active_workflow parameter' do
      it 'will create the workflow when set true' do
        expect { create(:permission_template, with_active_workflow: true) }.to change { Sipity::Workflow.count }.by(1)
      end
      it 'will not create the workflow when false (or not given)' do
        expect { create(:permission_template, with_active_workflow: false) }.not_to change { Sipity::Workflow.count }
      end
    end
  end

  describe '#agent_ids_for' do
    it 'queries the underlying access_grants' do
      template = create(:permission_template)
      to_find = template.access_grants.create!(agent_type: 'user', access: 'manage', agent_id: '123')
      template.access_grants.create!(agent_type: 'user', access: 'view', agent_id: '456')
      template.access_grants.create!(agent_type: 'group', access: 'manage', agent_id: '789')

      expect(template.agent_ids_for(agent_type: 'user', access: 'manage')).to eq([to_find.agent_id])
    end
  end

  describe "#admin_set" do
    it 'leverages AdminSet.find for the given permission_template' do
      expect(AdminSet).to receive(:find).with(permission_template.admin_set_id).and_return(admin_set)
      expect(permission_template.admin_set).to eq(admin_set)
    end
  end

  describe "#release_fixed_date?" do
    subject { permission_template.release_fixed_date? }
    context "with release_period='fixed'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }
      it { is_expected.to be false }
    end
  end

  describe "#release_no_delay?" do
    subject { permission_template.release_no_delay? }
    context "with release_period='now'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be false }
    end
  end

  describe "#release_before_date?" do
    subject { permission_template.release_before_date? }
    context "with release_period='before'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE } }
      it { is_expected.to be true }
    end
    context "with maximum embargo period (release_period of 1 year)" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be false }
    end
  end

  describe "#release_max_embargo?" do
    subject { permission_template.release_max_embargo? }
    context "with release_period of 1 year" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }
      it { is_expected.to be true }
    end
    context "with release_period of 2 years" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be false }
    end
  end

  describe "#release_date" do
    subject { permission_template.release_date }
    let(:today) { Time.zone.today }
    context "with today and release_fixed_date?" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: today } }
      it { is_expected.to eq today }
    end
    context "with today and release_before_date?" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today } }
      it { is_expected.to eq today }
    end
    context "with release_period of 6 months" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS } }
      it { is_expected.to eq today + 6.months }
    end
    context "with release_period of 1 year" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }
      it { is_expected.to eq today + 1.year }
    end
    context "with release_no_delay?" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }
      it { is_expected.to eq today }
    end
  end

  describe "#valid_release_date?" do
    let(:date) { Time.zone.today + 6.months }
    subject { permission_template.valid_release_date?(date) }
    context "with any release date and one is not required" do
      let(:attributes) { { admin_set_id: admin_set.id } }
      it { is_expected.to eq true }
    end
    context "with matching date and release_fixed_date?" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: date } }
      it { is_expected.to eq true }
    end
    context "with non-matching date and release_fixed_date?" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: date + 1.day } }
      it { is_expected.to eq false }
    end
    context "with exact match date and release_before_date?" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: date } }
      it { is_expected.to eq true }
    end
    context "with future, valid date and release_before_date?" do
      let(:date) { Time.zone.today + 1.day }
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: Time.zone.today + 1.month } }
      it { is_expected.to eq true }
    end
    context "with future, invalid date and release_before_date?" do
      let(:date) { Time.zone.today + 1.year }
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: Time.zone.today + 1.month } }
      it { is_expected.to eq false }
    end
    context "with today release and release_no_delay?" do
      let(:date) { Time.zone.today }
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }
      it { is_expected.to eq true }
    end
    context "with tomorrow release and release_no_delay?" do
      let(:date) { Time.zone.today + 1.day }
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }
      it { is_expected.to eq false }
    end
  end

  describe "#valid_visibility?" do
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    subject { permission_template.valid_visibility?(visibility) }
    context "with matching visibility" do
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }
      it { is_expected.to eq true }
    end
    context "with non-matching visibility" do
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED } }
      it { is_expected.to eq false }
    end
    context "with visibility when none required" do
      let(:attributes) { { admin_set_id: admin_set.id } }
      it { is_expected.to eq true }
    end
  end
end
