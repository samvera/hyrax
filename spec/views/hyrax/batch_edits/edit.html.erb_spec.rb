RSpec.describe 'hyrax/batch_edits/edit.html.erb', type: :view do
  let(:work) { create_for_repository(:work) }
  let(:change_set) { Hyrax::BatchEditChangeSet.new(work, batch_document_ids: [work.id.to_s]).prepopulate! }

  before do
    allow(Hyrax::Queries).to receive(:find_by).and_return(work)
    # this prevents AF from hitting Fedora (permissions is a related object)
    allow(work).to receive(:permissions_attributes=)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(change_set).to receive(:model).and_return(work)
    allow(change_set).to receive(:names).and_return(['title 1', 'title 2'])
    allow(change_set).to receive(:terms).and_return([:description, :license])
    allow(work).to receive(:visibility).and_return('open')
    allow(work).to receive(:permissions).and_return([])

    assign :change_set, change_set
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
