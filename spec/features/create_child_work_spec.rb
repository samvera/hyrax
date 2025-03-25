# frozen_string_literal: true
require 'redlock'

RSpec.describe 'Creating a new child Work', :workflow do
  let(:user) { create(:user) }
  let!(:sipity_entity) { create(:sipity_entity, proxy_for: parent) }
  let(:redlock_client_stub) do # stub out redis connection
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  end
  let!(:parent) do
    valkyrie_create(:monograph,
                    depositor: user.user_key,
                    title: ["Parent First"],
                    edit_users: [user.user_key])
  end
  let!(:persister) { Hyrax.persister }
  let!(:query_service) { Hyrax.query_service }

  before do
    sign_in user
    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    allow(CharacterizeJob).to receive(:perform_later)
    redlock_client_stub
  end

  it 'creates the child work' do
    visit "/concern/parent/#{parent.id}/monographs/new"
    work_title = 'My Test Work'
    within('form.new_monograph') do
      fill_in('Title', with: work_title)
      click_on('Save')
    end
    visit "/concern/monographs/#{parent.id}"

    expect(page).to have_content work_title
  end

  context "when it's being updated" do
    let(:curation_concern) { valkyrie_create(:monograph, depositor: user.user_key, edit_users: [user.user_key]) }
    let(:new_parent) { valkyrie_create(:monograph, depositor: user.user_key, edit_users: [user.user_key]) }
    let!(:cc_sipity_entity) { create(:sipity_entity, proxy_for: curation_concern) }
    let!(:new_sipity_entity) { create(:sipity_entity, proxy_for: new_parent) }

    before do
      parent.member_ids += [curation_concern.id]
      persister.save(resource: parent)
    end

    it 'can be updated' do
      visit "/concern/parent/#{parent.id}/monographs/#{curation_concern.id}/edit"
      click_on "Save"

      expect(query_service.find_by(id: parent.id).member_ids.count).to eq 1
    end

    it "doesn't lose other memberships" do
      new_parent.member_ids += [curation_concern.id]
      persister.save(resource: new_parent)

      visit "/concern/parent/#{parent.id}/monographs/#{curation_concern.id}/edit"
      click_on "Save"

      expect(query_service.find_by(id: parent.id).member_ids.count).to eq 1
      expect(query_service.find_by(id: new_parent.id).member_ids.count).to eq 1
    end

    context "with a parent that doesn't belong to this user" do
      let(:new_user) { create(:user) }
      let(:new_parent) { valkyrie_create(:monograph, depositor: new_user.user_key) }

      it "fails to update" do
        visit "/concern/parent/#{parent.id}/monographs/#{curation_concern.id}/edit"
        first("input#monograph_in_works_ids", visible: false).set new_parent.id
        first("input#parent_id", visible: false).set new_parent.id
        click_on "Save"

        expect(query_service.find_by(id: new_parent.id).member_ids.count).to eq 0
      end
    end
  end
end
