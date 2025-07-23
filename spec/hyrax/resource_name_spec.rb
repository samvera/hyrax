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

  it 'has a titleized human name' do
    expect(name.human).to eq name.human.titleize
  end

  context 'when a legacy resource is registered with Wings', :active_fedora do
    let(:work_class) { Hyrax::Test::BookResource }

    before do
      allow(Hyrax.config).to receive(:disable_wings).and_return(false)

      # Load Wings components directly since wings.rb has a guard clause
      unless defined?(Wings)
        require 'wings/model_registry'
        # Define the Wings module if it doesn't exist
        module Wings; end unless defined?(Wings)
      end

      Wings::ModelRegistry.register(Hyrax::Test::BookResource, Hyrax::Test::Book)
    end

    it 'uses the legacy route key' do
      expect(name.route_key).to eq 'test_books'
    end

    it 'uses the legacy singular route key' do
      expect(name.singular_route_key).to eq 'test_book'
    end

    it 'has a titleized human name' do
      expect(name.human).to eq name.human.titleize
    end
  end
end
