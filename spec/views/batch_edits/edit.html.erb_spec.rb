require 'spec_helper'

describe 'batch_edits/edit.html.erb' do
  let(:file_set) { stub_model(FileSet, id: nil, depositor: 'bob', rights: ['']) }

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign :names, ['title 1', 'title 2']
    assign :terms, [:description, :rights]
    assign :file_set, file_set
    view.lookup_context.view_paths.push "#{CurationConcerns::Engine.root}/app/views/curation_concerns/base"
    render
  end

  it "draws tooltip for description" do
    expect(rendered).to have_selector ".file_set_description a i.help-icon"
  end
end
