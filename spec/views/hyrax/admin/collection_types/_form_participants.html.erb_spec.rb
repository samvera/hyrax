RSpec.describe 'hyrax/admin/collection_types/_form_participants.html.erb', type: :view do
  let(:collection_type) { build(:collection_type) }
  let(:form) { Hyrax::Forms::Admin::CollectionTypeForm.new(collection_type: collection_type) }
  let(:collection_type_participant) { build(:collection_type_participant) }
  let(:participant_form) { Hyrax::Forms::Admin::CollectionTypeParticipantForm.new(collection_type_participant: collection_type_participant) }

  before do
    assign(:collection_type_participant, participant_form)
    assign(:form, form)
    render
  end
  it 'has the required selectors' do
    expect(rendered).to have_selector('#user-participants-form')
    expect(rendered).to have_selector('#group-participants-form')
  end
end
