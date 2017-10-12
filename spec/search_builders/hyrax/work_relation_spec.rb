RSpec.describe Hyrax::WorkRelation, :clean_repo do
  let!(:work) { create_for_repository(:work) }
  let!(:file_set) { create(:file_set) }
  let!(:collection) { create_for_repository(:collection) }

  it 'has works and not collections or file sets' do
    expect(subject).to eq [work]
  end
end
