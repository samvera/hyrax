# frozen_string_literal: true
RSpec.describe 'hyrax/batch_edits/edit.html.erb', :clean_repo, type: :view do
  let(:generic_work) { valkyrie_create(:monograph, depositor: 'bob@example.com') }
  let(:batch) { ['999'] }
  let(:form) { Hyrax::Forms::ResourceBatchEditForm.new(generic_work, nil, batch) }

  before do
    allow(Hyrax.query_service).to receive(:find_by).and_return(generic_work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(form).to receive(:model).and_return(generic_work)

    assign :form, form
    view.lookup_context.prefixes.push "hyrax/base"
    render
  end

  it "draws the page" do
    expect(rendered).to have_selector 'form[data-model="monograph"]'
    # Help for the description
    expect(rendered).to have_selector ".monograph_description p.help-block"

    # param key for the permissions javascript
    expect(rendered).to have_selector 'form#form_permissions[data-param-key="monograph"]'
    # batch ids for the permissions update form
    expect(rendered).to have_selector "input[name=\"batch_document_ids[]\"]", visible: false
  end
end
