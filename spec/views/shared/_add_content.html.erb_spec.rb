require 'spec_helper'

describe 'shared/_add_content.html.erb' do
  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'for people who can create Works and Collections' do
    let(:user) { create(:admin) }
    before do
      allow(view).to receive(:can?).and_return(true)
      render
    end

    it 'has links to create works and collections' do
      CurationConcerns.config.curation_concerns.each do |curation_concern_type|
        expect(rendered).to have_link("New #{curation_concern_type.human_readable_type}", href: new_polymorphic_path(curation_concern_type))
      end
      expect(rendered).to have_link('Add a Collection', href: collections.new_collection_path)
    end
  end

  context 'for people who can only create Collections' do
    let(:user) { create(:admin) }
    before do
      allow(view).to receive(:can?).and_return(true)
      allow(view).to receive(:can_ever_create_works?).and_return(false)
      render
    end

    it 'has links to add collections but not to add works' do
      CurationConcerns.config.curation_concerns.each do |curation_concern_type|
        expect(rendered).not_to have_link("New #{curation_concern_type.human_readable_type}", href: new_polymorphic_path(curation_concern_type))
      end
      expect(rendered).to have_link('Add a Collection', href: collections.new_collection_path)
    end
  end

  context 'for people who cannot create anything' do
    let(:user) { create(:user) }
    before do
      allow(view).to receive(:can?).and_return(false)
      render
    end

    it 'does not have links to add works or collections' do
      expect(rendered).not_to have_text('Add')
      expect(rendered).not_to have_text('Admin')
      CurationConcerns.config.curation_concerns.each do |curation_concern_type|
        expect(rendered).not_to have_link("New #{curation_concern_type.human_readable_type}", href: new_polymorphic_path(curation_concern_type))
      end
      expect(rendered).not_to have_link('Add a Collection', href: collections.new_collection_path)
    end
  end
end
