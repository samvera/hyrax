# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration do
  describe '.each_file_set' do
    def file_set(id)
      double("file set #{id}", id: Valkyrie::ID.new(id))
    end

    let(:registered) { [Hyrax::FileSet, Class.new] }
    let(:legacy_class) { registered.last }
    let(:postgres) { double('postgres query service') }

    before do
      allow(Hyrax::ModelRegistry).to receive(:file_set_classes).and_return(registered)
    end

    context 'with a composite query service' do
      let(:composite) { double('composite', services: [postgres]) }

      before { allow(Hyrax).to receive(:query_service).and_return(composite) }

      it 'asks the inner service for every registered file set class, not just the Valkyrie one' do
        allow(postgres).to receive(:find_all_of_model).with(model: Hyrax::FileSet).and_return([])
        allow(postgres).to receive(:find_all_of_model).with(model: legacy_class).and_return([file_set('a'), file_set('b')])

        expect(described_class.each_file_set.map { |fs| fs.id.to_s }).to eq %w[a b]
      end

      it 'yields each file set once even when several names return it' do
        allow(postgres).to receive(:find_all_of_model).and_return([file_set('a')])

        expect(described_class.each_file_set.count).to eq 1
      end

      it 'skips Wings query services, which read file sets from Fedora' do
        skip 'Wings is not loaded' unless defined?(Wings::Valkyrie::QueryService)
        wings = Wings::Valkyrie::QueryService.allocate
        allow(wings).to receive(:find_all_of_model).and_raise('Wings should not be queried')
        allow(composite).to receive(:services).and_return([wings, postgres])
        allow(postgres).to receive(:find_all_of_model).and_return([file_set('a')])

        expect(described_class.each_file_set.map { |fs| fs.id.to_s }).to eq ['a']
      end

      it 'yields nothing when no service has file sets' do
        allow(postgres).to receive(:find_all_of_model).and_return([])

        expect(described_class.each_file_set.to_a).to be_empty
      end
    end

    context 'with a single query service' do
      before { allow(Hyrax).to receive(:query_service).and_return(postgres) }

      it 'queries it directly' do
        allow(postgres).to receive(:find_all_of_model).and_return([file_set('a')])

        expect(described_class.each_file_set.map { |fs| fs.id.to_s }).to eq ['a']
      end
    end
  end

  describe '.scope' do
    around do |example|
      original = described_class.scope_provider
      example.run
      described_class.scope_provider = original
    end

    it 'is nil by default' do
      expect(described_class.scope).to be_nil
    end

    it 'comes from the configured provider' do
      described_class.scope_provider = -> { 'one.example.com' }

      expect(described_class.scope).to eq 'one.example.com'
    end

    it 'treats a blank label as no scope' do
      described_class.scope_provider = -> { '' }

      expect(described_class.scope).to be_nil
    end
  end
end
