RSpec.describe 'hyrax/admin/collection_types/_form_participant_table.html.erb', type: :view do
  let(:user) { create(:user) }
  let(:collection_type) { stub_model(Hyrax::CollectionType) }
  let(:collection_type_participant) { stub_model(Hyrax::CollectionTypeParticipant) }
  let(:form) do
    instance_double(Hyrax::Forms::Admin::CollectionTypeForm,
                    model_name: collection_type.model_name,
                    collection_type_participants: [collection_type_participant])
  end

  before do
    assign(:form, form)
  end

  describe 'Manager participants table' do
    before do
      render 'form_participant_table', access: 'managers', filter: :manager?
    end

    context 'managers exist' do
      let(:collection_type_participant) do
        stub_model(Hyrax::CollectionTypeParticipant,
                   agent_type: 'user',
                   agent_id: user.user_key,
                   access: 'manager')
      end

      it 'lists the managers in the table' do
        expect(rendered).to have_selector('h3', text: 'Managers')
        expect(rendered).to have_selector('table tbody', text: user.user_key)
      end
    end

    context 'no managers exist' do
      let(:collection_type_participant) { stub_model(Hyrax::CollectionTypeParticipant) }

      it 'displays a message and no table' do
        expect(rendered).to have_selector('h3', text: 'Managers')
        expect(rendered).not_to have_selector('table')
        expect(rendered).to have_content('No managers have been added to this collection type.')
      end
    end
  end

  describe 'Creator participants table' do
    before do
      render 'form_participant_table', access: 'creators', filter: :creator?
    end

    context 'creators exist' do
      let(:collection_type_participant) do
        stub_model(Hyrax::CollectionTypeParticipant,
                   agent_type: 'user',
                   agent_id: user.user_key,
                   access: 'creator')
      end

      it 'lists the creators in the table' do
        expect(rendered).to have_selector('h3', text: 'Creators')
        expect(rendered).to have_selector('table tbody', text: user.user_key)
      end
    end
    context 'no creators exist' do
      let(:collection_type_participant) { stub_model(Hyrax::CollectionTypeParticipant) }

      it 'displays a message and no table' do
        expect(rendered).to have_selector('h3', text: 'Creators')
        expect(rendered).not_to have_selector('table')
        expect(rendered).to have_content('No creators have been added to this collection type.')
      end
    end
  end
end
