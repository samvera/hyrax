# frozen_string_literal: true

RSpec.describe Hyrax::Identifier::Registrar do
  subject(:registrar) { described_class.new(builder: :NOT_A_REAL_BUILDER) }

  it 'is abstract' do
    expect { registrar.register!(object: :NOT_A_REAL_OBJECT) }
      .to raise_error NotImplementedError
  end

  describe '.for' do
    let(:builder) { instance_double(Hyrax::Identifier::Builder, build: 'moomin') }
    let(:fake_registrar) do
      Class.new do
        def initialize(*); end

        def register!(*)
          Struct.new(:identifier).new('moomin/123/abc')
        end
      end
    end

    before do
      allow(Hyrax.config).to receive(:identifier_registrars).and_return(moomin: fake_registrar)
    end

    it 'raises an error when a fake registrar type is passes' do
      expect { described_class.for(:NOT_A_REAL_TYPE, builder: builder) }
        .to raise_error ArgumentError
    end

    it 'chooses the right registrar type' do
      expect(described_class.for(:moomin, builder: builder))
        .to be_a fake_registrar
    end
  end
end
