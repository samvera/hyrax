# frozen_string_literal: true

RSpec.describe Hyrax::ResourceName do
  subject(:name) { described_class.new(work_class) }
  let(:work_class) { Monograph }

  it 'has a namespaced route key' do
    expect(name.route_key).to start_with 'hyrax_'
  end

  it 'has a namespaced singular route key' do
    expect(name.singular_route_key).to start_with 'hyrax_'
  end

  context 'when a legacy resource is registered with Wings' do
    let(:work_class) { Hyrax::Test::BookResource }

    it 'uses the legacy route key' do
      expect(name.route_key).to eq 'test_books'
    end

    it 'uses the legacy singular route key' do
      expect(name.singular_route_key).to eq 'test_book'
    end
  end
end
