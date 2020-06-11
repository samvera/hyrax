# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_form_discovery.html.erb', type: :view do
  let(:collection) { Collection.new }
  let(:collection_form) { Hyrax::Forms::CollectionForm.new(collection, double, double) }

  let(:form) do
    view.simple_form_for(collection, url: '/update') do |fs_form|
      return fs_form
    end
  end

  context "collection has open access" do
    before do
      allow(collection).to receive(:open_access?).and_return(true)
      allow(collection).to receive(:authenticated_only_access?).and_return(false)
      allow(collection).to receive(:private_access?).and_return(false)
      controller.request.path_parameters[:id] = 'j12345'
      assign(:form, collection_form)
      assign(:collection, collection)
      allow(view).to receive(:f).and_return(form)
      render
    end

    it "check open access is set" do
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=open][checked=true]')
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=authenticated]')
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=restricted]')
    end
  end

  context "collection has authenticated access" do
    before do
      allow(collection).to receive(:open_access?).and_return(false)
      allow(collection).to receive(:authenticated_only_access?).and_return(true)
      allow(collection).to receive(:private_access?).and_return(false)
      controller.request.path_parameters[:id] = 'j12345'
      assign(:form, collection_form)
      assign(:collection, collection)
      allow(view).to receive(:f).and_return(form)
      render
    end

    it "check authenticated access is set" do
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=open]')
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=authenticated][checked=true]')
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=restricted]')
    end
  end

  context "collection has restricted access" do
    before do
      allow(collection).to receive(:open_access?).and_return(false)
      allow(collection).to receive(:authenticated_only_access?).and_return(false)
      allow(collection).to receive(:private_access?).and_return(true)
      controller.request.path_parameters[:id] = 'j12345'
      assign(:form, collection_form)
      assign(:collection, collection)
      allow(view).to receive(:f).and_return(form)
      render
    end

    it "check restricted access is set" do
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=open]')
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=authenticated]')
      expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=restricted][checked=true]')
    end
  end
end
