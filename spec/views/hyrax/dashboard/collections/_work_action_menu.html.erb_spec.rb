require 'spec_helper'

RSpec.describe 'hyrax/dashboard/collections/_work_action_menu.html.erb', type: :view do
  let(:item) { stub_model(GenericWork) }
  let(:collection) { stub_model(Collection, id: 'xyz123z4', title: ["Make Collections Great Again"]) }
  let(:change_set) { Hyrax::CollectionChangeSet.new(collection) }

  before do
    allow(view).to receive(:display_trophy_link)
    assign(:change_set, change_set)
    render 'hyrax/dashboard/collections/work_action_menu', document: item
  end

  it "generates a form that can remove the item" do
    expect(rendered).to have_selector("form[action=\"#{hyrax.dashboard_collection_path(collection)}\"]")
    expect(rendered).to have_selector('input#collection_members[type="hidden"][value="remove"]', visible: false)
    expect(rendered).to have_selector("input[type='hidden'][name='batch_document_ids[]'][value='#{item.id}']", visible: false)
  end
end
