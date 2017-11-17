RSpec.describe AdminSet, type: :model do
  let(:gf1) { create(:generic_work, user: user) }
  let(:gf2) { create(:generic_work, user: user) }
  let(:gf3) { create(:generic_work, user: user) }

  let(:user) { create(:user) }

  subject { described_class.new(title: ['Some title']) }

  describe '#active_workflow' do
    it 'leverages Sipity::Workflow.find_active_workflow_for' do
      admin_set = build(:admin_set, id: 1234)
      expect(Sipity::Workflow).to receive(:find_active_workflow_for).with(admin_set_id: admin_set.id).and_return(:workflow)
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
      expect { create(:admin_set, with_permission_template: true) }.to change { Hyrax::PermissionTemplate.count }.by(1)
    end

    it 'will not create a permission_template by default' do
      expect { create(:admin_set) }.not_to change { Hyrax::PermissionTemplate.count }
    end

    it 'will create a permission_template with attributes' do
      permission_template = create(:admin_set,
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

  describe '.after_destroy' do
    let(:permission_template_access) { create(:permission_template_access) }

    it 'will destroy the associated permission template and permission template access' do
      admin_set = create(:admin_set, with_permission_template: true)
      permission_template_access.permission_template_id = admin_set.permission_template.id
      permission_template_access.save
      expect { admin_set.destroy }.to change { Hyrax::PermissionTemplate.count }.by(-1).and change { Hyrax::PermissionTemplateAccess.count }.by(-1)
    end
  end

  describe "#to_solr" do
    let(:admin_set) do
      build(:admin_set, title: ['A good title'],
                        creator: ['jcoyne@justincoyne.com'])
    end
    let(:solr_document) { admin_set.to_solr }

    it "has title and creator information" do
      expect(solr_document).to include 'title_tesim' => ['A good title'],
                                       'title_sim' => ['A good title'],
                                       'creator_ssim' => ['jcoyne@justincoyne.com']
    end
  end

  describe "#members" do
    it "is empty by default" do
      skip 'This test is plagued by this bug https://github.com/samvera/active_fedora/issues/1238'
      expect(subject.members).to be_empty
    end

    context "adding members" do
      context "using assignment" do
        subject { described_class.create!(title: ['Some title'], members: [gf1, gf2]) }

        it "has many files" do
          expect(subject.reload.members).to match_array [gf1, gf2]
        end
      end

      context "using append" do
        before do
          subject.members = [gf1]
          subject.save
        end
        it "allows new files to be added" do
          subject.reload
          subject.members << gf2
          subject.save
          expect(subject.reload.members).to match_array [gf1, gf2]
        end
      end
    end
  end

  describe ".default_set?" do
    context "with default AdminSet ID" do
      it "returns true" do
        expect(AdminSet.default_set?(described_class::DEFAULT_ID)).to be true
      end
    end

    context "with a non-default  ID" do
      it "returns false" do
        expect(AdminSet.default_set?('different-id')).to be false
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
      before { expect(described_class).to receive(:exists?).and_return(true) }
      it 'returns the DEFAULT_ID without creating the admin set' do
        expect(Hyrax::AdminSetCreateService).not_to receive(:create_default_admin_set)
        expect(subject).to eq(described_class::DEFAULT_ID)
      end
    end
    describe 'if it does not already exist' do
      before { expect(described_class).to receive(:exists?).and_return(false) }
      it 'returns the DEFAULT_ID and creates the admin set' do
        expect(Hyrax::AdminSetCreateService).to receive(:create_default_admin_set).with(admin_set_id: described_class::DEFAULT_ID, title: described_class::DEFAULT_TITLE)
        expect(subject).to eq(described_class::DEFAULT_ID)
      end
    end
  end

  describe "#destroy" do
    context "with member works" do
      before do
        subject.members = [gf1, gf2]
        subject.save!
        subject.destroy
      end

      it "does not delete adminset or member works" do
        expect(subject.errors.full_messages).to eq ["Administrative set cannot be deleted as it is not empty"]
        expect(AdminSet.exists?(subject.id)).to be true
        expect(GenericWork.exists?(gf1.id)).to be true
        expect(GenericWork.exists?(gf2.id)).to be true
      end
    end

    context "with no member works" do
      before do
        subject.members = []
        subject.save!
        subject.destroy
      end

      it "deletes the adminset" do
        expect(AdminSet.exists?(subject.id)).to be false
      end
    end

    context "is default adminset" do
      before do
        subject.members = []
        subject.id = described_class::DEFAULT_ID
        subject.save!
        subject.destroy
      end

      it "does not delete the adminset" do
        expect(subject.errors.full_messages).to eq ["Administrative set cannot be deleted as it is the default set"]
        expect(AdminSet.exists?(described_class::DEFAULT_ID)).to be true
      end
    end
  end
end
