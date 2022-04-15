# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/spy_listener'

RSpec.describe 'Deleting a valkyrie work', type: :feature, valkyrie_adapter: :test_adapter, index_adapter: :solr_index do
  let(:work) do
    FactoryBot.valkyrie_create(:monograph,
                               :as_member_of_multiple_collections,
                               :with_admin_set,
                               :with_member_file_sets,
                               title: 'babys first monograph',
                               edit_users: [user.user_key])
  end

  let(:listener) { Hyrax::Specs::SpyListener.new }
  let(:user)     { FactoryBot.create(:user) }

  before do
    sign_in user
    Hyrax.publisher.subscribe(listener)
  end

  after { Hyrax.publisher.unsubscribe(listener) }

  it 'deletes the work' do
    visit hyrax_monograph_path(work)
    click_on('Delete', match: :first)
    expect(page).to have_current_path(hyrax.my_works_path, ignore_query: true)
    expect(page).to have_content 'Deleted babys first monograph'

    expect { Hyrax.query_service.find_by(id: work.id) }
      .to raise_error Valkyrie::Persistence::ObjectNotFoundError

    # publishes object.deleted
    expect(listener.object_deleted&.payload)
      .to include(id: work.id.to_s, user: user)

    # deletes all members
    work.member_ids.each do |file_set_id|
      expect { Hyrax.query_service.find_by(id: file_set_id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
