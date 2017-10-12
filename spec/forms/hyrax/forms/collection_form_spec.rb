RSpec.describe Hyrax::Forms::CollectionForm do
  describe "#terms" do
    subject { described_class.terms }

    it do
      is_expected.to eq [:resource_type,
                         :title,
                         :creator,
                         :contributor,
                         :description,
                         :keyword,
                         :license,
                         :publisher,
                         :date_created,
                         :subject,
                         :language,
                         :representative_id,
                         :thumbnail_id,
                         :identifier,
                         :based_near,
                         :related_url,
                         :visibility,
                         :collection_type_gid]
    end
  end

  let(:collection) { build(:collection) }
  let(:ability) { Ability.new(create(:user)) }
  let(:repository) { double }
  let(:form) { described_class.new(collection, ability, repository) }

  describe "#primary_terms" do
    subject { form.primary_terms }

    it { is_expected.to eq([:title, :description]) }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it do
      is_expected.to eq [
        :creator,
        :contributor,
        :keyword,
        :license,
        :publisher,
        :date_created,
        :subject,
        :language,
        :identifier,
        :based_near,
        :related_url,
        :resource_type
      ]
    end
  end

  describe '#display_additional_fields?' do
    subject { form.display_additional_fields? }

    context 'with no secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([])
      end
      it { is_expected.to be false }
    end
    context 'with secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([:foo, :bar])
      end
      it { is_expected.to be true }
    end
  end

  describe "#id" do
    subject { form.id }

    it { is_expected.to be_nil }
  end

  describe "#required?" do
    subject { form.required?(:title) }

    it { is_expected.to be true }
  end

  describe "#human_readable_type" do
    subject { form.human_readable_type }

    it { is_expected.to eq 'Collection' }
  end

  describe "#member_ids" do
    before do
      allow(collection).to receive(:member_ids).and_return(['9999'])
    end
    subject { form.member_ids }

    it { is_expected.to eq ['9999'] }
  end

  describe ".build_permitted_params" do
    subject { described_class.build_permitted_params }

    it do
      is_expected.to eq [{ resource_type: [] },
                         { title: [] },
                         { creator: [] },
                         { contributor: [] },
                         { description: [] },
                         { keyword: [] },
                         { license: [] },
                         { publisher: [] },
                         { date_created: [] },
                         { subject: [] },
                         { language: [] },
                         :representative_id,
                         :thumbnail_id,
                         { identifier: [] },
                         { based_near: [] },
                         { related_url: [] },
                         :visibility,
                         :collection_type_gid,
                         { permissions_attributes: [:type, :name, :access, :id, :_destroy] }]
    end
  end

  describe '#select_files' do
    subject { form.select_files }

    let(:collection) { create(:collection) }
    let(:repository) { Hyrax::CollectionsController.new.repository }

    context 'without any works/files attached' do
      it { is_expected.to be_empty }
    end

    context 'with a work/file attached', :with_nested_reindexing do
      let!(:work) { create(:work_with_one_file, :public, member_of_collections: [collection]) }
      let(:title) { work.file_sets.first.title.first }
      let(:file_id) { work.file_sets.first.id }

      it 'returns a hash of with file title as key and file id as value' do
        expect(subject).to eq(title => file_id)
      end
    end
  end

  describe "#permission_template" do
    subject { form.permission_template }

    context "when the PermissionTemplate doesn't exist" do
      let(:model) { create(:collection) }

      it "gets created" do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to be_instance_of Hyrax::PermissionTemplate
      end
    end

    context "when the PermissionTemplate exists" do
      let(:form) { described_class.new(model, ability, repository) }
      let(:permission_template) { Hyrax::PermissionTemplate.find_by(source_id: model.id) }
      let(:model) { create(:collection, with_permission_template: true) }

      it "uses the existing template" do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to eq permission_template
      end
    end
  end
end
