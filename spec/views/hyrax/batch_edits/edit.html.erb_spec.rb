# frozen_string_literal: true
RSpec.describe 'hyrax/batch_edits/edit.html.erb', type: :view do
  let(:generic_work) { stub_model(GenericWork, id: '999', depositor: 'bob', license: ['']) }
  let(:batch) { ['999'] }
  let(:form) { Hyrax::Forms::BatchEditForm.new(generic_work, nil, batch) }

  before do
    allow(ActiveFedora::Base).to receive(:find).and_return(generic_work)
    # TODO: stub_model is not stubbing new_record? correctly on ActiveFedora models.
    allow(generic_work).to receive(:new_record?).and_return(false)
    # this prevents AF from hitting Fedora (permissions is a related object)
    allow(generic_work).to receive(:permissions_attributes=)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(form).to receive(:model).and_return(generic_work)
    allow(form).to receive(:names).and_return(['title 1', 'title 2'])
    allow(form).to receive(:terms).and_return([:description, :license])
    allow(generic_work).to receive(:visibility).and_return('open')
    allow(generic_work).to receive(:permissions).and_return([])

    assign :form, form
    view.extend Hyrax::PermissionsHelper
    view.lookup_context.prefixes.push "hyrax/base"
    render
  end

  it "draws the page" do
    expect(rendered).to have_selector 'form[data-model="generic_work"]'
    # Help for the description
    expect(rendered).to have_selector ".generic_work_description p.help-block"

    # param key for the permissions javascript
    expect(rendered).to have_selector 'form#form_permissions[data-param-key="generic_work"]'
    # batch ids for the permissions update form
    expect(rendered).to have_selector "input[name=\"batch_document_ids[]\"]", visible: false
  end
end
