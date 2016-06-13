
describe "sufia/homepage/_featured_works.html.erb" do
  let(:list) { FeaturedWorkList.new }
  subject { rendered }
  before { assign(:featured_work_list, list) }

  context "without featured works" do
    before { render }
    it {
      is_expected.to have_content 'No works have been featured'
      is_expected.not_to have_selector('form')
    }
  end

  context "with featured works" do
    let(:doc) { SolrDocument.new(id: '12345678',
                                 title_tesim: ['Doc title'],
                                 has_model_ssim: ['GenericWork']) }
    let(:presenter) { Sufia::WorkShowPresenter.new(doc, nil) }
    let(:featured_work) { FeaturedWork.new }
    before do
      allow(view).to receive(:can?).with(:update, FeaturedWork).and_return(false)
      allow(view).to receive(:render_thumbnail_tag).with(presenter, width: 90)
      allow(list).to receive(:empty?).and_return(false)
      allow(list).to receive(:featured_works).and_return([featured_work])
      allow(featured_work).to receive(:presenter).and_return(presenter)
      render
    end

    it {
      is_expected.not_to have_content 'No works have been featured'
      is_expected.not_to have_selector('form')
      is_expected.to have_selector('ol#featured_works')
    }
  end
end
