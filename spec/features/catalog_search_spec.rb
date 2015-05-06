require 'spec_helper'

describe 'catalog searching', :type => :feature do

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    sign_in :user
    visit '/'
  end

  context 'with works and collections' do
    let!(:jills_work) {
      GenericWork.new.tap do |work|
        work.title = ["Jill's Research"]
        work.tag = ['jills_tag', 'shared_tag']
        work.apply_depositor_metadata('jilluser')
        work.read_groups = ['public']
        work.save!
      end
    }

    let!(:jacks_work) {
      GenericWork.new.tap do |work|
        work.title = ["Jack's Research"]
        work.tag = ['jacks_tag', 'shared_tag']
        work.apply_depositor_metadata('jackuser')
        work.read_groups = ['public']
        work.save!
      end
    }

    let!(:collection) {
      Collection.new.tap do |c|
        c.title = 'Collection Title'
        c.tag = ['collection_tag', 'shared_tag']
        c.apply_depositor_metadata('jilluser')
        c.read_groups = ['public']
        c.save!
      end
    }

    it 'performing a search' do
      within('#masthead_controls') do
        fill_in('search-field-header', with: 'shared_tag')
        click_button('Go')
      end

      expect(page).to have_content('Search Results')
      expect(page).to have_content(jills_work.title.first)
      expect(page).to have_content(jacks_work.title.first)
      expect(page).to have_content(collection.title)
    end

  end

end
