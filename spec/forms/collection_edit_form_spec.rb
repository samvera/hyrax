require 'spec_helper'

describe CurationConcerns::Forms::CollectionEditForm do
  let(:collection) { Collection.new }
  let(:form) { described_class.new(collection) }

  describe '#terms' do
    subject { form.terms }
    it do
      is_expected.to eq [:resource_type, :title, :creator, :contributor, :description,
                         :tag, :rights, :publisher, :date_created, :subject, :language,
                         :identifier, :based_near, :related_url]
    end
  end

  describe ".build_permitted_params" do
    subject { described_class.build_permitted_params }
    it { is_expected.to eq [{ resource_type: [] },
                            :title,
                            { creator: [] },
                            { contributor: [] },
                            :description,
                            { tag: [] },
                            { rights: [] },
                            { publisher: [] },
                            { date_created: [] },
                            { subject: [] },
                            { language: [] },
                            { identifier: [] },
                            { based_near: [] },
                            { related_url: [] },
                            :visibility] }
  end

  describe 'unique?' do
    context 'with :title' do
      subject { described_class.unique?(:title) }
      it { is_expected.to be true }
    end
  end

  describe '#select_files' do
    context 'without any works/files attached' do
      subject { form.select_files }
      it { is_expected.to be_empty }
    end

    context 'with a work/file attached' do
      let(:work) { create(:work_with_one_file) }
      let(:title) { work.generic_files.first.title.first }
      let(:file_id) { work.generic_files.first.id }
      let(:collection_with_file) do
        Collection.create!(title: 'foo', members: [work]) do |c|
          c.apply_depositor_metadata('jcoyne')
        end
      end

      it 'returns a hash of with file title as key and file id as value' do
        form_with_files = described_class.new(collection_with_file)
        expect(form_with_files.select_files).to eq(title => file_id)
      end
    end
  end
end
