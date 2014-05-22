require 'spec_helper'

describe 'curation_concern/base/show.html.erb' do

  let!(:curation_concern) { FactoryGirl.create(:private_generic_work) }

  context "for editors" do
    it 'has links to edit and add to collections' do
      allow(view).to receive(:can?).and_return(true)
      render file: 'curation_concern/base/show', locals: { curation_concern: curation_concern }
      expect(view.content_for(:second_row)).to have_link("Edit This Generic Work", href: edit_polymorphic_path([:curation_concern, curation_concern]))
      expect(view.content_for(:second_row)).to have_link("Add to a Collection", href: add_member_form_collections_path(collectible_id:curation_concern.pid))
    end
  end
  context "for non-editors" do
    it 'does not have links to edit' do
      render file: 'curation_concern/base/show', locals: { curation_concern: curation_concern }
      expect(view.content_for(:second_row)).not_to have_content("Edit this Generic Work")
    end
    it 'has link to add to a collection' do
      render file: 'curation_concern/base/show', locals: { curation_concern: curation_concern }
      expect(view.content_for(:second_row)).to have_link("Add to a Collection", href: add_member_form_collections_path(collectible_id:curation_concern.pid))
    end
  end
end
