# frozen_string_literal: true

# samvera/hyrax#7572. The dropdown is deliberately never touched: that is the
# workflow the issue reports.
#
# Excluded in flexible mode: the flex test profile (m3_profile-allinson.yaml) does
# not define `relationships`, so Monograph has no such attribute there and the
# factory raises before a page renders. Matches
# spec/forms/hyrax/forms/compound_metadata_form_spec.rb.
RSpec.describe 'Editing a work with a work_or_url compound', :clean_repo, type: :feature, js: true,
                                                                          unless: Hyrax.config.flexible? do
  let(:user) { create(:user, groups: 'librarians') }

  let!(:default_admin_set) do
    valkyrie_create(:hyrax_admin_set,
                    title: Hyrax::AdminSetCreateService::DEFAULT_TITLE,
                    edit_users: [user.user_key],
                    with_permission_template: true,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user.user_key,
                                      access: Hyrax::PermissionTemplateAccess::DEPOSIT }])
  end

  # An existing value is required: the bug manifests as the OLD value persisting.
  # creator/record_info fill the form's required fields so it can submit at all.
  let(:work) do
    valkyrie_create(:monograph,
                    title: ['Relationship host'],
                    creator: ['Test Author'],
                    record_info: ['Test record info'],
                    relationships: [{ 'item' => 'https://example.com/old', 'type' => 'References' }],
                    depositor: user.user_key,
                    admin_set_id: default_admin_set.id,
                    edit_users: [user.user_key])
  end

  before do
    # Compounds persist as JSONB; the Fedora adapter cannot serialize a plain-hash
    # compound at all, so the stored entry never round-trips back into the form.
    skip 'requires the Postgres metadata adapter (compounds are JSONB)' unless
      Valkyrie.config.metadata_adapter.is_a?(Valkyrie::Persistence::Postgres::MetadataAdapter)

    sign_in user
    Hyrax::DefaultAdministrativeSet.update(default_admin_set_id: default_admin_set.id)
  end

  it 'shows a stored URL in a field the user can see and edit' do
    visit edit_hyrax_monograph_path(work)

    field = find_field('monograph_relationships_attributes_0_item', visible: :all)
    expect(field.value).to eq('https://example.com/old')
    expect(field).to be_visible
  end

  # The only coverage of bindPickerToTarget/toggleUrlField, which run on selection
  # rather than on load.
  context 'choosing a work from the picker' do
    let!(:other_work) do
      valkyrie_create(:monograph, title: ['Journal of Findable Things'],
                                  creator: ['Test Author'],
                                  record_info: ['Test record info'],
                                  depositor: user.user_key,
                                  admin_set_id: default_admin_set.id,
                                  read_users: [user.user_key])
    end

    def pick_from_search(term)
      find('.select2-container', match: :first).click
      find('input.select2-input').set(term)
      find('.select2-result-label', text: 'Journal of Findable Things').click
    end

    it 'writes the work id into the submitting field and hides the URL box' do
      visit edit_hyrax_monograph_path(work)
      pick_from_search('Findable')

      field = find_field('monograph_relationships_attributes_0_item', visible: :all)
      expect(field.value).to eq(other_work.id.to_s)
      expect(field).not_to be_visible
    end

    it 'stores the work id, so the show page links to that work' do
      visit edit_hyrax_monograph_path(work)
      pick_from_search('Findable')

      check('agreement')
      click_on('Save changes')

      expect(page).to have_link('Journal of Findable Things')
    end
  end

  context 'when the stored value is a scheme-less URL' do
    let(:work) do
      valkyrie_create(:monograph,
                      title: ['Relationship host'],
                      creator: ['Test Author'],
                      record_info: ['Test record info'],
                      relationships: [{ 'item' => 'www.example.org/thing', 'type' => 'References' }],
                      depositor: user.user_key,
                      admin_set_id: default_admin_set.id,
                      edit_users: [user.user_key])
    end

    it 'stays visible and editable' do
      visit edit_hyrax_monograph_path(work)

      field = find_field('monograph_relationships_attributes_0_item', visible: :all)
      expect(field.value).to eq('www.example.org/thing')
      expect(field).to be_visible
    end
  end

  it 'saves a typed URL without any dropdown interaction' do
    visit edit_hyrax_monograph_path(work)
    expect(page).to have_content('Edit Work')

    fill_in 'monograph_relationships_attributes_0_item', with: 'https://example.com/new'

    check('agreement')
    click_on('Save changes')

    expect(page).to have_current_path(hyrax_monograph_path(work, locale: 'en'))
    expect(page).to have_content('https://example.com/new')
    expect(page).not_to have_content('https://example.com/old')
  end
end
