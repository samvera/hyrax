require 'spec_helper'

describe 'sufia/batch_uploads/_form.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:ability) { double('ability', current_user: user) }
  let(:form) { Sufia::Forms::BatchUploadForm.new(work, ability) }
  let(:user) { stub_model(User) }

  before do
    view.lookup_context.view_paths.push "#{CurationConcerns::Engine.root}/app/views/curation_concerns/base"
    view.lookup_context.view_paths.push 'app/views/sufia/batch_uploads'
    view.lookup_context.view_paths.push 'app/views/curation_concerns/base'
    allow(view).to receive(:curation_concern).and_return(work)
    assign(:form, form)
    allow(controller).to receive_messages(current_user: user,
                                          controller_name: 'batch_uploads',
                                          action_name: 'new',
                                          repository: CurationConcerns::GenericWorksController.new.repository,
                                          blacklight_config: CurationConcerns::GenericWorksController.new.blacklight_config)
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
