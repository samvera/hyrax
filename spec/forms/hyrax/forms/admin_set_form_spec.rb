# frozen_string_literal: true
RSpec.describe Hyrax::Forms::AdminSetForm, :active_fedora do
  let(:ability) { Ability.new(create(:user)) }
  let(:repository) { double }
  let(:form) { described_class.new(model, ability, repository) }

  describe "[] accessors" do
    let(:model) { build(:admin_set, description: ['one']) }

    it "cast to scalars" do
      expect(form[:description]).to eq 'one'
    end
  end

  describe "#thumbnail_title" do
    subject { form.thumbnail_title }

    context "when the admin_set has a thumbnail" do
      let(:thumbnail) { stub_model(FileSet, title: ['Ulysses']) }
      let(:model) { AdminSet.new(thumbnail: thumbnail) }

      it { is_expected.to eq "Ulysses" }
    end

    context "when the admin_set has no thumbnail" do
      let(:model) { AdminSet.new }

      it { is_expected.to be nil }
    end
  end

  describe "#permission_template" do
    subject { form.permission_template }

    context "when the PermissionTemplate doesn't exist" do
      let(:model) { create(:admin_set) }

      it "gets created" do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to be_instance_of Hyrax::PermissionTemplate
      end
    end

    context "when the PermissionTemplate exists" do
      let(:permission_template) { Hyrax::PermissionTemplate.find_by(source_id: model.id) }
      let(:model) { create(:admin_set, with_permission_template: true) }

      it "uses the existing template" do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to eq permission_template
      end
    end
  end

  describe "model_attributes" do
    let(:raw_attrs) { ActionController::Parameters.new(title: 'test title') }

    subject { described_class.model_attributes(raw_attrs) }

    it "casts to enums" do
      expect(subject[:title]).to eq ['test title']
    end
  end

  describe '#select_files' do
    subject { form.select_files }

    let(:repository) { Hyrax::CollectionsController.new.blacklight_config.repository }

    context 'without any works/files attached' do
      let(:model) { create(:admin_set) }

      it { is_expected.to be_empty }
    end

    context 'with a work/file attached' do
      let(:work) { create(:work_with_one_file) }
      let(:title) { work.file_sets.first.title.first }
      let(:file_id) { work.file_sets.first.id }
      let(:model) do
        create(:admin_set, members: [work])
      end

      it 'returns a hash of with file title as key and file id as value' do
        expect(subject).to eq(title => file_id)
      end
    end
  end
end
