# frozen_string_literal: true
RSpec.describe Hyrax::AbstractTypeRelation, :clean_repo do
  before do
    stub_const 'AnotherWork', Class.new
  end
  it 'returns nil when no allowable types exist' do
    allow(subject).to receive(:allowable_types).and_return([])
    expect(subject.search_model_clause).to be_nil
  end
  it 'returns GenericWork when allowable types exist' do
    allow(subject).to receive(:allowable_types).and_return([GenericWork])
    expect(subject.search_model_clause).to include('GenericWork')
  end
  it 'returns both works when allowable types exist' do
    allow(subject).to receive(:allowable_types).and_return([GenericWork, AnotherWork])
    expect(subject.search_model_clause).to include('GenericWork')
    expect(subject.search_model_clause).to include('AnotherWork')
  end
end
