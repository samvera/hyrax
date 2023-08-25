# frozen_string_literal: true
RSpec.describe FileSetAttachedEventJob do
  let(:user) { FactoryBot.create(:user) }
  let(:mock_time) { Time.zone.at(1) }

  let(:event) do
    {
      action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> " \
              "has attached <a href=\"/concern/file_sets/#{file_set.id}\">A Contained FileSet</a> " \
              "to <a href=\"/concern/#{curation_concern.model_name.collection}/#{curation_concern.id}\">MacBeth</a>",
      timestamp: '1'
    }
  end

  before do
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    allow(Hyrax::TimeService).to receive(:time_in_utc).at_least(:once).and_return(mock_time)
  end

  context 'with a FileSet', :active_fedora do
    let(:file_set) { curation_concern.file_sets.first }
    let(:curation_concern) { create(:work_with_one_file, title: ['MacBeth'], user: user) }

    it "logs the event to the right places" do
      expect do
        described_class.perform_now(file_set, user)
      end.to change { user.profile_events.length }.by(1)
                                                  .and change { file_set.events.length }.by(1)
                                                                                        .and change { curation_concern.events.length }.by(1)

      expect(user.profile_events.first).to eq(event)
      expect(curation_concern.events.first).to eq(event)
      expect(file_set.events.first).to eq(event)
    end
  end

  context 'with a Hyrax::FileSet (valkyrie)' do
    let(:file_set) do
      FactoryBot.valkyrie_create(:hyrax_file_set, :in_work, work: curation_concern, title: 'A Contained FileSet')
    end

    let(:curation_concern) { FactoryBot.valkyrie_create(:monograph, title: ['MacBeth']) }

    it 'logs events to user profile, file_set, and work' do
      expect { described_class.perform_now(file_set, user) }
        .to change { user.profile_events.length }
        .by(1)
        .and change { file_set.events.length }
        .by(1)
        .and change { curation_concern.events.length }.by(1)

      expect(user.profile_events).to contain_exactly(event)
      expect(curation_concern.events).to contain_exactly(event)
      expect(file_set.events).to contain_exactly(event)
    end
  end
end
