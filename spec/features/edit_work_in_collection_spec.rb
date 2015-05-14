require 'spec_helper'

describe "In Show Collection", :type => :feature do
  let(:user) { create :jill }

  let!(:work) {
    GenericWork.new.tap do |work|
      work.title = ['work title abc']
      work.apply_depositor_metadata(user.user_key)
      work.read_groups = ['public']
      work.save!
    end
  }

  let!(:collection) {
    Collection.new.tap do |f|
      f.title = 'collection title abc'
      f.apply_depositor_metadata(user.user_key)
      f.read_groups = ['public']
      f.members = [work]
      f.save
    end
  }

  before { sign_in user }

  context "when signed in" do

    before do
      sign_in user
    end

    it 'should redirect to edit work page when clicking on edit link' do
      visit "collections/#{collection.id}"
      click_link("edit_work_link_#{work.id}") 
      # TODO: replace with real work edit page
      expect(page).to have_content "todo edit"
    end

  end
end

