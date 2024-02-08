# frozen_string_literal: true
RSpec.describe AdminSet, :active_fedora, type: :model do
  let(:gf1) { create(:generic_work, user: user) }
  let(:gf2) { create(:generic_work, user: user) }
  let(:gf3) { create(:generic_work, user: user) }

  let(:user) { create(:user) }

  subject { described_class.new(title: ['Some title']) }

  its(:internal_resource) { is_expected.to eq('AdminSet') }
  its(:to_rdf_representation) { is_expected.to eq('AdminSet') }

  describe '#active_workflow' do
    it 'leverages Sipity::Workflow.find_active_workflow_for' do
      admin_set = build(:admin_set, id: 1234)
      expect(Sipity::Workflow).to receive(:find_active_workflow_for).with(admin_set_id: admin_set.id).and_return(:workflow)
      expect(admin_set.active_workflow).to eq(:workflow)
    end
  end

  describe '#permission_template' do
    it 'queries for a Hyrax::PermissionTemplate with a matching source_id' do
      admin_set = build(:admin_set, id: '123')
      permission_template = build(:permission_template)
      expect(Hyrax::PermissionTemplate).to receive(:find_by!).with(source_id: '123').and_return(permission_template)
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
                        creator: ['jcoyne@justincoyne.com'],
                        alternative_title: ['A bad title'],
                        description: ['a description'])
    end

    it "has title and creator information" do
      expect(admin_set.to_solr).to include 'title_tesim' => ['A good title'],
                                           'title_sim' => ['A good title'],
                                           'creator_ssim' => ['jcoyne@justincoyne.com']
    end

    it 'indexes all properties' do
      keys = ["system_create_dtsi", "system_modified_dtsi", "has_model_ssim",
              :id, "title_tesim", "title_sim", "alternative_title_tesim", "description_tesim",
              "creator_ssim", "thumbnail_path_ss", "generic_type_sim",
              "human_readable_type_sim", "human_readable_type_tesim"]

      expect(admin_set.to_solr.keys).to contain_exactly(*keys)
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

  describe "#destroy" do
    context "with member works" do
      before do
        subject.members = [gf1, gf2]
        subject.save!
        subject.destroy
      end

      it "does not delete adminset or member works" do
        expect(subject.errors.full_messages).to eq ["Administrative set cannot be deleted as it is not empty"]
        expect(described_class.exists?(subject.id)).to be true
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
        expect(described_class.exists?(subject.id)).to be false
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
        expect(described_class.exists?(described_class::DEFAULT_ID)).to be true
      end
    end
  end

  describe '#assign_id' do
    context 'with noid true' do
      around(:each) do |example|
        Hyrax.config.enable_noids = true
        example.run
        Hyrax.config.enable_noids = false
      end

      it 'should assign a NOID' do
        new_id = subject.assign_id
        expect(new_id).to be
        expect(new_id.size).to eq(9)
      end
    end

    context 'with noid false' do
      it 'should assign a UUID if no other id is minted' do
        new_id = subject.assign_id
        expect(new_id).to be
        expect(new_id.size).to eq(36)
      end
    end
  end
end
