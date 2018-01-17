RSpec.describe AdminSet, type: :model do
  let(:gf1) { create_for_repository(:work, user: user) }
  let(:gf2) { create_for_repository(:work, user: user) }
  let(:gf3) { create_for_repository(:work, user: user) }

  let(:user) { create(:user) }

  subject(:admin_set) { described_class.new(title: ['Some title']) }

  describe '#active_workflow' do
    it 'leverages Sipity::Workflow.find_active_workflow_for' do
      admin_set = build(:admin_set, id: 1234)
      expect(Sipity::Workflow).to receive(:find_active_workflow_for).with(admin_set_id: admin_set.id.to_s).and_return(:workflow)
      expect(admin_set.active_workflow).to eq(:workflow)
    end
  end

  describe '#permission_template' do
    it 'queries for a Hyrax::PermissionTemplate with a matching admin_set_id' do
      admin_set = build(:admin_set, id: '123')
      permission_template = build(:permission_template)
      expect(Hyrax::PermissionTemplate).to receive(:find_by!).with(admin_set_id: '123').and_return(permission_template)
      expect(admin_set.permission_template).to eq(permission_template)
    end
  end

  describe 'factories' do
    it 'will create a permission_template when one is requested' do
      expect { create_for_repository(:admin_set, with_permission_template: true) }.to change { Hyrax::PermissionTemplate.count }.by(1)
    end

    it 'will not create a permission_template by default' do
      expect { create_for_repository(:admin_set) }.not_to change { Hyrax::PermissionTemplate.count }
    end

    it 'will create a permission_template with attributes' do
      permission_template = create_for_repository(:admin_set,
                                                  with_permission_template: {
                                                    visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
                                                    release_date: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
                                                    release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS
                                                  }).permission_template
      expect(permission_template.visibility).to eq(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(permission_template.release_period).to eq(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS)
      expect(permission_template.release_date).to eq(6.months.from_now.to_date)
    end
  end

  describe "#members" do
    it "is empty by default" do
      skip 'This test is plagued by this bug https://github.com/samvera/active_fedora/issues/1238'
      expect(subject.members).to be_empty
    end

    context "adding members" do
      context "using assignment" do
        subject { reloaded.members.map(&:id) }

        let(:admin_set) { create_for_repository(:admin_set, title: ['Some title']) }
        let!(:gf1) { create_for_repository(:work, user: user, admin_set_id: admin_set.id) }
        let!(:gf2) { create_for_repository(:work, user: user, admin_set_id: admin_set.id) }
        let(:reloaded) { Hyrax::Queries.find_by(id: admin_set.id) }

        it { is_expected.to match_array [gf1.id, gf2.id] }
      end
    end
  end

  describe ".default_set?" do
    context "with default AdminSet ID" do
      it "returns true" do
        expect(AdminSet.default_set?(described_class::DEFAULT_ID)).to be true
      end
    end

    context "with a non-default ID" do
      it "returns false" do
        expect(AdminSet.default_set?('different-id')).to be false
      end
    end

    context "with default AdminSet ID as a Valkyrie::ID" do
      it "returns true" do
        expect(AdminSet.default_set?(Valkyrie::ID.new(described_class::DEFAULT_ID))).to be true
      end
    end
  end

  describe "#default_set?", :clean_repo do
    context "with default AdminSet ID" do
      subject { described_class.new(id: described_class::DEFAULT_ID).default_set? }

      it { is_expected.to be_truthy }
    end

    context "with a non-default  ID" do
      subject { described_class.new(id: 'why-would-you-name-the-default-chupacabra?').default_set? }

      it { is_expected.to be_falsey }
    end
  end

  describe ".find_or_create_default_admin_set_id" do
    subject { described_class.find_or_create_default_admin_set_id }

    describe 'if it already exists' do
      before { expect(Hyrax::Queries).to receive(:exists?).and_return(true) }
      it 'returns the DEFAULT_ID without creating the admin set' do
        expect(Hyrax::AdminSetCreateService).not_to receive(:create_default_admin_set)
        expect(subject).to eq(described_class::DEFAULT_ID)
      end
    end
    describe 'if it does not already exist' do
      before { expect(Hyrax::Queries).to receive(:exists?).and_return(false) }
      it 'returns the DEFAULT_ID and creates the admin set' do
        expect(Hyrax::AdminSetCreateService).to receive(:create_default_admin_set).with(admin_set_id: described_class::DEFAULT_ID, title: described_class::DEFAULT_TITLE)
        expect(subject).to eq(described_class::DEFAULT_ID)
      end
    end
  end
end
