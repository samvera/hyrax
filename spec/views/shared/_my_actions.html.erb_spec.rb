require 'spec_helper'

describe 'shared/_my_actions.html.erb' do
  include CurationConcerns::SearchPathsHelper
  context "for admins" do
    it 'has links to edit and add to collections' do
      allow(view).to receive(:current_user).and_return(FactoryGirl.create(:user))
      allow(view).to receive(:can?).and_return(true)
      render partial: 'shared/my_actions'
      expect(rendered).to have_link("My Works", href: search_path_for_my_works)
      expect(rendered).to have_link("My Collections", href: search_path_for_my_collections)
    end
  end
  context "for non-admins" do
    it 'does not have links to edit' do
      allow(view).to receive(:current_user).and_return(FactoryGirl.create(:user))
      allow(view).to receive(:can?).and_return(false)
      render partial: 'shared/my_actions'
      expect(rendered).not_to have_text("My Works")
      expect(rendered).not_to have_text("My Collections")
    end
  end
end
