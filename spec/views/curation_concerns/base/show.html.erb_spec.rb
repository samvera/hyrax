require 'spec_helper'

describe 'curation_concerns/base/show.html.erb' do
  let!(:curation_concern) { FactoryGirl.create(:private_generic_work) }

  context 'for editors' do
    before do
      allow(view).to receive(:can?).and_return(true)
    end

    it 'has links to edit' do # and add to collections' do
      render file: 'curation_concerns/base/show', locals: { curation_concern: curation_concern }
      expect(rendered).to have_link('Edit This Generic Work', href: edit_polymorphic_path([:curation_concerns, curation_concern]))
      # expect(rendered).to have_selector "a[data-toggle='modal'][data-target='##{curation_concern.to_param}-modal']", text: "Add to a Collection"
      # expect(rendered).to have_selector("div.modal##{curation_concern.to_param}-modal form[action='#{collections.collections_path}'] input[value='Add to collection']")
    end
  end

  context 'for non-editors' do
    it 'does not have links to edit' do # , but has add to collection' do
      render file: 'curation_concerns/base/show', locals: { curation_concern: curation_concern }
      expect(rendered).not_to have_content('Edit this Generic Work')

      # expect(rendered).to have_selector "a[data-toggle='modal'][data-target='##{curation_concern.to_param}-modal']", text: "Add to a Collection"
      # expect(rendered).to have_selector("div.modal##{curation_concern.to_param}-modal form[action='#{collections.collections_path}'] input[value='Add to collection']")
    end
  end
end
