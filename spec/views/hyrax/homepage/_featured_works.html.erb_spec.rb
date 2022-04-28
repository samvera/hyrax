# frozen_string_literal: true
RSpec.describe "hyrax/homepage/_featured_works.html.erb", type: :view do
  let(:list) { FeaturedWorkList.new }

  subject { rendered }

  before { assign(:featured_work_list, list) }

  context "without featured works" do
    before { render }
    it do
      is_expected.to have_content 'No works have been featured'
      is_expected.not_to have_selector('form')
    end
  end

  context "with featured works" do
    let(:doc) do
      SolrDocument.new(id: '12345678',
                       title_tesim: ['Doc title'],
                       has_model_ssim: ['GenericWork'])
    end
    let(:presenter) { Hyrax::WorkShowPresenter.new(doc, nil) }
    let(:featured_work) { FeaturedWork.new }

    before do
      allow(view).to receive(:can?).with(:update, FeaturedWork).and_return(false)
      allow(list).to receive(:empty?).and_return(false)
      allow(list).to receive(:featured_works).and_return([featured_work])
      allow(featured_work).to receive(:presenter).and_return(presenter)
      render
    end

    it do
      is_expected.not_to have_content 'No works have been featured'
      is_expected.not_to have_selector('form')
      is_expected.to have_selector('ol#featured_works')
    end
  end
end
