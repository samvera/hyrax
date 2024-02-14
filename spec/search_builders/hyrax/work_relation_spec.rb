# frozen_string_literal: true

# NOTE: This is an ActiveFedora query service that is currently being used
#   in the following classes/modules:
#   Hyrax::SingularSubresourceController, Hyrax::WorkUsage, Hyrax::UserStatImporter,
#   Hyrax::WorkQueryService, Hyrax::Statistics::QueryService, Hyrax::Statistics::Works::OverTime,
#   MoveAllWorksToAdminSet, and Hyrax::ResourceSync::ResourceListWriter
RSpec.describe Hyrax::WorkRelation, :active_fedora, :clean_repo do
  let!(:work) { create(:generic_work) }
  let!(:file_set) { create(:file_set) }
  let!(:collection) { build(:collection_lw) }

  it 'has works and not collections or file sets' do
    expect(subject).to eq [work]
  end
end
