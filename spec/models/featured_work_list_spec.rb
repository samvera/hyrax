# frozen_string_literal: true
RSpec.describe FeaturedWorkList, type: :model do
  let(:user) { create(:user) }
  let(:work1) { valkyrie_create(:hyrax_work) }
  let(:work2) { valkyrie_create(:hyrax_work) }

  describe 'featured_works' do
    before do
      create(:featured_work, work_id: work1.id)
      create(:featured_work, work_id: work2.id)
    end

    it 'is a list of the featured work objects, each with the generic_work\'s solr_doc' do
      presenter_ids = subject.featured_works.map { |fw| fw.presenter.id }
      expect(presenter_ids).to contain_exactly(work1.id, work2.id)
      subject.featured_works.each do |fw|
        expect(fw.presenter).to be_kind_of Hyrax::WorkShowPresenter
      end
    end

    context 'when one of the works is deleted' do
      before do
        transaction = Hyrax::Transactions::WorkDestroy.new
        transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work1)
      end

      it 'is a list of the remaining featured work objects, each with the generic_work\'s solr_doc' do
        expect(subject.featured_works.size).to eq 1
        presenter = subject.featured_works.first.presenter
        expect(presenter).to be_kind_of Hyrax::WorkShowPresenter
        expect(presenter.id).to eq work2.id
      end
    end
  end

  describe '#featured_works_attributes=' do
    # We don't need to persist the given work. This saves a few LDP calls.
    let(:work_id) { 'no-need-to-persist' }
    let(:featured_work) { create(:featured_work, work_id: work_id) }

    let(:attributes) do
      ActionController::Parameters.new(
        "0" => {
          "id" => featured_work.id,
          "order" => "5"
        }
      ).permit!
    end
    let(:instance) { described_class.new }

    subject { instance.featured_works_attributes = attributes }

    it "sets order" do
      subject
      expect(featured_work.order).to eq 5
    end
  end

  it { is_expected.to delegate_method(:empty?).to(:featured_works) }
end
