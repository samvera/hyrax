describe FeaturedWorkList, type: :model do
  let(:work1) { create(:generic_work) }
  let(:work2) { create(:generic_work) }

  describe 'featured_works' do
    before do
      create(:featured_work, work_id: work1.id)
      create(:featured_work, work_id: work2.id)
    end

    it 'is a list of the featured work objects, each with the generic_work\'s solr_doc' do
      expect(subject.featured_works.size).to eq 2
      presenter = subject.featured_works.first.presenter
      expect(presenter).to be_kind_of Hyrax::WorkShowPresenter
      expect(presenter.id).to eq work1.id
    end
  end

  describe 'file deleted' do
    before do
      create(:featured_work, work_id: work1.id)
      create(:featured_work, work_id: work2.id)
      work1.destroy
    end

    it 'is a list of the remaining featured work objects, each with the generic_work\'s solr_doc' do
      expect(subject.featured_works.size).to eq 1
      presenter = subject.featured_works.first.presenter
      expect(presenter).to be_kind_of Hyrax::WorkShowPresenter
      expect(presenter.id).to eq work2.id
    end
  end

  it { is_expected.to delegate_method(:empty?).to(:featured_works) }
end
