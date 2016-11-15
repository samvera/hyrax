require 'spec_helper'

feature 'Editing attached files' do
  let(:user) { create(:user) }
  let!(:parent) { create(:work_with_one_file, user: user) }
  let!(:file_set) { parent.file_sets.first }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
  end
  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before do
    sign_in user
    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    expect(CharacterizeJob).to receive(:perform_later)
  end

  it 'updates the file' do
    visit "/concern/generic_works/#{parent.id}"
    click_link 'Edit'
    expect(page).to have_content "Updating Attached File to \"Test title\""

    attach_file('Upload a file', fixture_file_path('files/image.png'))
    click_button 'Update Attached File'

    expect(page).to have_content 'The file A Contained FileSet has been updated.'

    # TODO: this stuff belongs in an Actor or Controller test:
    file_set.reload
    expect(file_set.original_file.original_name).to eq 'image.png'
    expect(file_set.original_file.mime_type).to eq 'image/png'
  end
end
