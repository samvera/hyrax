require 'spec_helper'

RSpec.describe Sufia::WorkRelation do
  let!(:work) { create(:generic_work) }
  let!(:file_set) { create(:file_set) }
  let!(:collection) { create(:collection) }
  it 'has works and not collections or file sets' do
    expect(subject).to eq [work]
  end
end
