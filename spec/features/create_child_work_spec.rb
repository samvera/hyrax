require 'redlock'

RSpec.feature 'Creating a new child Work', :workflow do
  let(:user) { create(:user) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
  end
  let(:redlock_client_stub) do # stub out redis connection
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  end
  let!(:parent) { create_for_repository(:work, user: user, title: ["Parent First"]) }

  before do
    sign_in user
    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    allow(CharacterizeJob).to receive(:perform_later)
    redlock_client_stub
  end

  it 'creates the child work' do
    visit "/concern/parent/#{parent.id}/generic_works/new"
    work_title = 'My Test Work'
    within('form.new_generic_work') do
      fill_in('Title', with: work_title)
      click_on('Save')
    end
    visit "/concern/generic_works/#{parent.id}"
    expect(page).to have_content work_title
  end

  context "when it's being updated" do
    let(:persister) { Valkyrie.config.metadata_adapter.persister }
    let(:curation_concern) { create_for_repository(:work, user: user) }
    let(:new_parent) { create_for_repository(:work, user: user) }
    let!(:cc_sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: curation_concern.to_global_id.to_s)
    end
    let!(:new_sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: new_parent.to_global_id.to_s)
    end

    before do
      parent.member_ids << curation_concern.id
      persister.save(resource: parent)
    end

    it 'can be updated' do
      visit "/concern/parent/#{parent.id}/generic_works/#{curation_concern.id}/edit"
      click_on "Save"
      reloaded = Hyrax::Queries.find_by(id: parent.id)

      expect(reloaded.member_ids.length).to eq 1
    end

    it "doesn't lose other memberships" do
      new_parent.member_ids << curation_concern.id
      persister.save(resource: new_parent)

      visit "/concern/parent/#{parent.id}/generic_works/#{curation_concern.id}/edit"
      click_on "Save"

      reloaded = Hyrax::Queries.find_by(id: parent.id)
      expect(reloaded.member_ids.length).to eq 1

      new_parent_reloaded = Hyrax::Queries.find_by(id: new_parent.id)
      expect(new_parent_reloaded.member_ids.length).to eq 1

      cc_reloaded = Hyrax::Queries.find_by(id: curation_concern.id)
      expect(cc_reloaded.in_works_ids.length).to eq 2
    end

    context "with a parent that doesn't belong to this user" do
      let(:new_user) { create(:user) }
      let(:new_parent) { create_for_repository(:work, user: new_user) }

      it "fails to update" do
        visit "/concern/parent/#{parent.id}/generic_works/#{curation_concern.id}/edit"
        first("input#generic_work_in_works_ids", visible: false).set new_parent.id
        first("input#parent_id", visible: false).set new_parent.id
        click_on "Save"

        new_parent_reloaded = Hyrax::Queries.find_by(id: new_parent.id)
        expect(new_parent_reloaded.member_ids.length).to eq 0
        expect(page).to have_content "Works can only be related to each other if user has ability to edit both."
      end
    end
  end
end
