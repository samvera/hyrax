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

  describe '.each_original' do
    let(:file_sets) { %w[a b c d].map { |id| double("fs #{id}", id: Valkyrie::ID.new(id)) } }
    let(:originals) { { 'a' => double('orig a'), 'b' => nil, 'c' => double('orig c'), 'd' => double('orig d') } }

    before do
      allow(described_class).to receive(:each_file_set) { |&block| file_sets.each(&block) }
      allow(Hyrax.custom_queries).to receive(:find_original_file) { |file_set:| originals[file_set.id.to_s] }
    end

    it 'yields each file set that has an original, and skips the rest' do
      seen = []
      described_class.each_original { |file_set, _original| seen << file_set.id.to_s }

      expect(seen).to eq %w[a c d]
    end

    it 'reports a file set whose original cannot be loaded, and carries on' do
      allow(Hyrax.custom_queries).to receive(:find_original_file).with(file_set: file_sets[0]).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      errors = []
      seen = []

      described_class.each_original(on_error: ->(file_set, error) { errors << [file_set.id.to_s, error.class] }) { |file_set, _| seen << file_set.id.to_s }

      expect(errors).to eq [['a', Valkyrie::Persistence::ObjectNotFoundError]]
      expect(seen).to eq %w[c d]
    end

    it 'skips quietly when no error handler is given' do
      allow(Hyrax.custom_queries).to receive(:find_original_file).and_raise(StandardError, 'boom')

      expect { described_class.each_original { |_fs, _o| nil } }.not_to raise_error
    end

    it 'stops after the limit' do
      seen = []
      described_class.each_original(limit: 2) { |file_set, _| seen << file_set.id.to_s }

      expect(seen).to eq %w[a c]
    end

    it 'does not count a yielded file set toward the limit when the block returns false' do
      seen = []
      described_class.each_original(limit: 1) do |file_set, _|
        seen << file_set.id.to_s
        false
      end

      expect(seen).to eq %w[a c d]
    end

    it 'ticks the progress reporter for every file set, including ones without an original' do
      progress = instance_double(Hyrax::S3Migration::Progress, tick: nil)

      described_class.each_original(progress:) { |_fs, _o| true }

      expect(progress).to have_received(:tick).exactly(4).times
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
