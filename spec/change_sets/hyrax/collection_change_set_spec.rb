# frozen_string_literal: true

RSpec.describe Hyrax::CollectionChangeSet do
  let(:collection) { build(:collection) }
  let(:form) { described_class.new(collection) }

  describe "#terms" do
    subject { described_class.terms }

    it do
      is_expected.to contain_exactly(:resource_type,
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
                                     :visibility)
    end
  end

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
        :license,
        :publisher,
        :date_created,
        :subject,
        :language,
        :identifier,
        :based_near,
        :related_url,
        :resource_type,
        :thumbnail_id,
        :representative_id,
        :visibility
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

  describe '#select_files' do
    subject { form.select_files }

    let(:collection) { create_for_repository(:collection) }
    let(:repository) { Hyrax::CollectionsController.new.repository }

    context 'without any works/files attached' do
      it { is_expected.to be_empty }
    end

    context 'with a work/file attached' do
      let!(:work) { create_for_repository(:work_with_one_file, :public, member_of_collection_ids: [collection.id]) }
      let(:file_set) { Hyrax::Queries.find_members(resource: work, model: ::FileSet).first }
      let(:title) { file_set.title.first }
      let(:file_id) { file_set.id.to_s }

      it 'returns a hash of with file title as key and file id as value' do
        expect(subject).to eq(title => file_id)
      end
    end
  end
end
