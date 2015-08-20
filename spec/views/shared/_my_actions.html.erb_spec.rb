require 'spec_helper'

describe 'shared/_my_actions.html.erb' do
  include CurationConcerns::SearchPathsHelper

  before do
    allow(view).to receive(:current_user).and_return(build(:user, email: 'geraldine@example.com'))
  end
  context "for admins" do

    before do
      allow(view).to receive(:can?).and_return(true)
      render
    end

    it 'has links' do
      expect(rendered).to have_text 'geraldine@example.com'
      expect(rendered).to have_link("My Works", href: search_path_for_my_works)
      expect(rendered).to have_link("My Collections", href: search_path_for_my_collections)
      expect(rendered).to have_link("Embargos", href: embargoes_path)
      expect(rendered).to have_link("Leases", href: leases_path)
    end
  end

  context "for non-admins" do
    before do
      allow(view).to receive(:can?).and_return(false)
      render
    end
    it 'does not have links to edit' do
      expect(rendered).to have_text 'geraldine@example.com'
      expect(rendered).not_to have_text("My Works")
      expect(rendered).not_to have_text("My Collections")
    end
  end
end
