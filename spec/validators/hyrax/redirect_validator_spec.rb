# frozen_string_literal: true

RSpec.describe Hyrax::RedirectValidator do
  subject(:validator) { described_class.new(attributes: [:redirects]) }

  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :id, :redirects
      validates_with Hyrax::RedirectValidator, attributes: [:redirects]
    end
  end
  let(:record) do
    record_class.new.tap do |r|
      r.id = 'self-id'
      r.redirects = entries
    end
  end
  let(:entry_class) { Struct.new(:path, :canonical, keyword_init: true) }
  let(:entries) { [] }

  before do
    allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
    allow(Flipflop).to receive(:redirects?).and_return(true)
    allow(Hyrax::RedirectsLookup).to receive(:taken?).and_return(false)
  end

  describe '#validate_each' do
    context 'when both gates are open' do
      let(:entries) { [entry_class.new(path: '/handle/12345/678', canonical: true)] }

      it 'is valid' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'when the config is off' do
      before { allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false) }
      let(:entries) { [entry_class.new(path: 'no-leading-slash', canonical: false)] }

      it 'short-circuits without raising or recording errors' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'when the Flipflop is off' do
      before { allow(Flipflop).to receive(:redirects?).and_return(false) }
      let(:entries) { [entry_class.new(path: 'no-leading-slash', canonical: false)] }

      it 'short-circuits without recording errors' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'when entries is blank' do
      let(:entries) { [] }

      it 'is valid' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end

    context 'with a blank path' do
      let(:entries) { [entry_class.new(path: '', canonical: false)] }

      it 'records a blank-path error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/can't be blank/)
      end
    end

    context 'with a path missing a leading slash' do
      let(:entries) { [entry_class.new(path: 'handle/12345/678', canonical: false)] }

      it 'records a format error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/not a valid redirect path/)
      end
    end

    context 'with whitespace in the path' do
      let(:entries) { [entry_class.new(path: '/has space', canonical: false)] }

      it 'records a format error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/not a valid redirect path/)
      end
    end

    context 'with a query string in the path' do
      let(:entries) { [entry_class.new(path: '/foo?bar=baz', canonical: false)] }

      it 'records a format error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/not a valid redirect path/)
      end
    end

    context 'with a path under a reserved Hyrax prefix' do
      let(:entries) { [entry_class.new(path: '/concern/generic_works/abc', canonical: false)] }

      it 'records a reserved-prefix error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/reserved prefix/)
      end
    end

    context 'with a path that exactly matches a reserved prefix' do
      let(:entries) { [entry_class.new(path: '/dashboard', canonical: false)] }

      it 'records a reserved-prefix error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/reserved prefix/)
      end
    end

    context 'with two entries sharing the same path on the same record' do
      let(:entries) do
        [
          entry_class.new(path: '/handle/1', canonical: false),
          entry_class.new(path: '/handle/1', canonical: false)
        ]
      end

      it 'records an intra-record duplicate error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/listed more than once/)
      end
    end

    context 'when the path is taken on another record' do
      let(:entries) { [entry_class.new(path: '/handle/12345/678', canonical: false)] }

      before do
        allow(Hyrax::RedirectsLookup)
          .to receive(:taken?)
          .with('/handle/12345/678', except_id: 'self-id')
          .and_return(true)
      end

      it 'records a global-uniqueness error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/already in use/)
      end
    end

    context 'when more than one entry is marked canonical' do
      let(:entries) do
        [
          entry_class.new(path: '/a', canonical: true),
          entry_class.new(path: '/b', canonical: true)
        ]
      end

      it 'records an at-most-one-canonical error' do
        record.valid?
        expect(record.errors[:redirects]).to include(/at most one redirect entry may be marked canonical/)
      end
    end

    context 'when zero entries are marked canonical' do
      let(:entries) do
        [
          entry_class.new(path: '/a', canonical: false),
          entry_class.new(path: '/b', canonical: false)
        ]
      end

      it 'is valid (canonical is optional)' do
        record.valid?
        expect(record.errors[:redirects]).to be_empty
      end
    end
  end
end
