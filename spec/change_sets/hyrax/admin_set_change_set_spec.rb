# frozen_string_literal: true

RSpec.describe Hyrax::AdminSetChangeSet do
  let(:ability) { Ability.new(create(:user)) }
  let(:repository) { double }
  let(:change_set) { described_class.new(model) }

  describe "[] accessors" do
    let(:model) { build(:admin_set, description: ['one']) }

    it "cast to scalars" do
      expect(change_set[:description]).to eq 'one'
    end
  end

  describe "#thumbnail_title" do
    subject { change_set.thumbnail_title }

    context "when the admin_set has a thumbnail" do
      let(:thumbnail) { create_for_repository(:file_set, title: ['Ulysses']) }
      let(:model) { create_for_repository(:admin_set, thumbnail_id: thumbnail.id.to_s) }

      it { is_expected.to eq "Ulysses" }
    end

    context "when the admin_set has no thumbnail" do
      let(:model) { AdminSet.new }

      it { is_expected.to be nil }
    end
  end

  describe "#permission_template" do
    subject { change_set.permission_template }

    context "when the PermissionTemplate doesn't exist" do
      let(:model) { create_for_repository(:admin_set) }

      it "gets created" do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to be_instance_of Hyrax::PermissionTemplate
      end
    end

    context "when the PermissionTemplate exists" do
      let(:permission_template) { Hyrax::PermissionTemplate.find_by(admin_set_id: model.id.to_s) }
      let(:model) { create_for_repository(:admin_set, with_permission_template: true) }

      it "uses the existing template" do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to eq permission_template
      end
    end
  end

  describe '#select_files' do
    subject { change_set.select_files }

    let(:repository) { Hyrax::CollectionsController.new.repository }
    let(:model) { create_for_repository(:admin_set) }

    context 'without any works/files attached' do
      it { is_expected.to be_empty }
    end

    context 'with a work/file attached' do
      let(:file_set) { create_for_repository(:file_set, title: [title]) }
      let!(:work) { create_for_repository(:work, member_ids: [file_set.id], admin_set_id: model.id) }
      let(:title) { 'test title' }

      it 'returns a hash of with file title as key and file id as value' do
        expect(subject).to eq(title => file_set.id.to_s)
      end
    end
  end
end
