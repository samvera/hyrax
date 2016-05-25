
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
    before do
      allow(view).to receive(:can?).with(:update, FeaturedWork).and_return(false)
      allow(list).to receive(:empty?).and_return(false)
      render
    end

    it {
      is_expected.not_to have_content 'No works have been featured'
      is_expected.not_to have_selector('form')
      is_expected.to have_selector('ol#featured_works')
    }
  end
end
