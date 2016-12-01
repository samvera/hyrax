describe Sufia::PermissionTemplate do
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { described_class.new(attributes) }
  let(:attibutes) { { admin_set_id: admin_set.id } }

  describe "#release_fixed?" do
    subject { permission_template.release_fixed? }
    context "with release_period='fixed'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }
      it { is_expected.to be false }
    end
  end

  describe "#release_no_delay?" do
    subject { permission_template.release_no_delay? }
    context "with release_period='now'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be false }
    end
  end

  describe "#release_before_date?" do
    subject { permission_template.release_before_date? }
    context "with release_period='before'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be false }
    end
  end

  describe "#release_embargo?" do
    subject { permission_template.release_embargo? }
    context "with release_period='1yr'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR } }
      it { is_expected.to be true }
    end
    context "with release_period='2yrs'" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS } }
      it { is_expected.to be true }
    end
    context "with other release_period" do
      let(:attributes) { { admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED } }
      it { is_expected.to be false }
    end
  end
end
