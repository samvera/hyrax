require 'spec_helper'

describe 'curation_concern/base/show.html.erb' do

  let!(:curation_concern) { FactoryGirl.create(:private_generic_work) }
  let(:second) { view.content_for(:second_row) }

  context "for editors" do
    before do
      allow(view).to receive(:can?).and_return(true)
    end

    it 'has links to edit and add to collections' do
      render file: 'curation_concern/base/show', locals: { curation_concern: curation_concern }
      expect(second).to have_link("Edit This Generic Work", href: edit_polymorphic_path([:curation_concern, curation_concern]))
      expect(second).to have_selector "a[data-toggle='modal'][data-target='##{curation_concern.to_param}-modal']", text: "Add to a Collection"
      expect(second).to have_selector("div.modal##{curation_concern.to_param}-modal form[action='#{collections.collections_path}'] input[value='Add to collection']")
    end
  end

  context "for non-editors" do
    it 'does not have links to edit, but has add to collection' do
      render file: 'curation_concern/base/show', locals: { curation_concern: curation_concern }
      expect(second).not_to have_content("Edit this Generic Work")

      expect(second).to have_selector "a[data-toggle='modal'][data-target='##{curation_concern.to_param}-modal']", text: "Add to a Collection"
      expect(second).to have_selector("div.modal##{curation_concern.to_param}-modal form[action='#{collections.collections_path}'] input[value='Add to collection']")
    end
  end
end
