# frozen_string_literal: true
RSpec.describe Hyrax::WorkRelation, :clean_repo do
  let!(:work) { create(:generic_work) }
  let!(:file_set) { create(:file_set) }
  let!(:collection) { build(:collection_lw) }

  it 'has works and not collections or file sets' do
    expect(subject).to eq [work]
  end
end
