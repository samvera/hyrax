require 'spec_helper'

describe 'curation_concerns/base/_form.html.erb', type: :view do
  let(:ability) { double }
  let(:user) { stub_model(User) }
  let(:form) do
    CurationConcerns::GenericWorkForm.new(work, ability)
  end

  before do
    # view.lookup_context.view_paths.push 'app/views/curation_concerns'
    # allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:curation_concern).and_return(work)
  end

  let(:page) do
    view.simple_form_for form do |f|
      render 'curation_concerns/base/form', f: f
    end
    Capybara::Node::Simple.new(rendered)
  end

  context "when the work has been saved before" do
    before do
      allow(work).to receive(:new_record?).and_return(false)
      assign(:form, form)
    end

    let(:work) { stub_model(GenericWork, id: '456', etag: '123456') }

    it "renders the form with the version" do
      expect(page).to have_selector("input#generic_work_version[value=\"123456\"]", visible: false)
    end
  end
end
