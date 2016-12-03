describe Hyrax::Forms::CollectionForm do
  describe "#terms" do
    subject { described_class.terms }

    it do
      is_expected.to eq [:resource_type,
                         :title,
                         :creator,
                         :contributor,
                         :description,
                         :keyword,
                         :rights,
                         :publisher,
                         :date_created,
                         :subject,
                         :language,
                         :representative_id,
                         :thumbnail_id,
                         :identifier,
                         :based_near,
                         :related_url,
                         :visibility]
    end
  end

  let(:collection) { build(:collection) }
  let(:form) { described_class.new(collection) }

  describe "#primary_terms" do
    subject { form.primary_terms }
    it { is_expected.to eq([:title]) }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it do
      is_expected.to eq [
        :creator,
        :contributor,
        :description,
        :keyword,
        :rights,
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
                         { rights: [] },
                         { publisher: [] },
                         { date_created: [] },
                         { subject: [] },
                         { language: [] },
                         :representative_id,
                         :thumbnail_id,
                         { identifier: [] },
                         { based_near: [] },
                         { related_url: [] },
                         :visibility]
    end
  end

  describe '#select_files' do
    context 'without any works/files attached' do
      subject { form.select_files }
      it { is_expected.to be_empty }
    end

    context 'with a work/file attached' do
      let(:work) { create(:work_with_one_file) }
      let(:title) { work.file_sets.first.title.first }
      let(:file_id) { work.file_sets.first.id }
      let(:collection_with_file) do
        create(:collection, members: [work])
      end

      it 'returns a hash of with file title as key and file id as value' do
        form_with_files = described_class.new(collection_with_file)
        expect(form_with_files.select_files).to eq(title => file_id)
      end
    end
  end
end
