require 'spec_helper'

describe 'sufia/batch_uploads/_form.html.erb' do
  let(:work) { GenericWork.new }
  let(:ability) { double }
  let(:form) { Sufia::BatchUploadForm.new(work, ability) }

  before do
    view.lookup_context.view_paths.push "#{CurationConcerns::Engine.root}/app/views/curation_concerns/base"
    view.lookup_context.view_paths.push 'app/views/sufia/batch_uploads'
    view.lookup_context.view_paths.push 'app/views/curation_concerns/base'
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:form, form)
  end

  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  it "draws the page" do
    expect(page).to have_selector("form[action='/batch_uploads']")
    # No title, because it's captured per file (e.g. Display label)
    expect(page).not_to have_selector("input#generic_work_title")
    expect(page).to have_link("New Work", href: "/concern/generic_works/new")
    expect(page).to have_link("Cancel", href: "/dashboard")
    expect(rendered).to match(/Display label/)
  end
end
