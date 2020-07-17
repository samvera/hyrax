# frozen_string_literal: true

RSpec.shared_examples 'a Hyrax::Identifier::Builder' do
  subject(:builder) { described_class.new }

  describe '#build' do
    it 'returns an identifier string' do
      expect(builder.build(hint: 'moomin'))
        .to respond_to :to_str
    end
  end
end

RSpec.shared_examples 'a Hyrax::Identifier::Registrar' do
  subject(:registrar) { described_class.new(builder: builder) }
  let(:builder)       { instance_double(Hyrax::Identifier::Builder, build: 'moomin') }
  let(:object)        { instance_double(GenericWork, id: 'moomin_id') }

  it { is_expected.to have_attributes(builder: builder) }

  describe '#register!' do
    it 'creates an identifier record' do
      expect(registrar.register!(object: object).identifier)
        .to respond_to :to_str
    end
  end
end
