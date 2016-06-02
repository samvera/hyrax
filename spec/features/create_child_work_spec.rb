require 'spec_helper'
require 'redlock'

feature 'Creating a new child Work' do
  let(:user) { FactoryGirl.create(:user) }

  let(:redlock_client_stub) { # stub out redis connection
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  }
  let(:parent) { FactoryGirl.create(:generic_work, user: user, title: ["Parent First"]) }

  before do
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    allow(CharacterizeJob).to receive(:perform_later)
    redlock_client_stub
    parent
  end

  it 'creates the child work' do
    visit "/concern/parent/#{parent.id}/generic_works/new"
    work_title = 'My Test Work'
    within('form.new_generic_work') do
      fill_in('Title', with: work_title)
      click_on('Create Generic work')
    end
    expect(page).to have_content parent.title.first
    visit "/concern/generic_works/#{parent.id}"
    expect(page).to have_content work_title
  end

  context "when it's being updated" do
    let(:curation_concern) { FactoryGirl.create(:generic_work, user: user) }
    before do
      parent.ordered_members << curation_concern
      parent.save!
    end
    it 'can be updated' do
      visit "/concern/parent/#{parent.id}/generic_works/#{curation_concern.id}/edit"
      click_on "Update Generic work"

      expect(parent.reload.ordered_members.to_a.length).to eq 1
    end
    it "doesn't lose other memberships" do
      new_parent = FactoryGirl.create(:generic_work, user: user)
      new_parent.ordered_members << curation_concern
      new_parent.save!

      visit "/concern/parent/#{parent.id}/generic_works/#{curation_concern.id}/edit"
      click_on "Update Generic work"

      expect(parent.reload.ordered_members.to_a.length).to eq 1
      expect(new_parent.reload.ordered_members.to_a.length).to eq 1

      expect(curation_concern.reload.in_works_ids.length).to eq 2
    end
  end
end
