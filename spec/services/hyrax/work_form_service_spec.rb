# frozen_string_literal: true

RSpec.describe Hyrax::WorkFormService, :active_fedora do
  subject(:form_service) { described_class }
  let(:work)             { GenericWork.new }

  describe '.form_class' do
    it 'returns a form class by constant name convention' do
      expect(form_service.form_class(work)).to eq Hyrax::GenericWorkForm
    end

    context 'with a missing form class' do
      let(:work) { Hyrax::Test::SimpleWorkLegacy.new }

      it 'raises a NameError' do
        expect { form_service.form_class(work) }.to raise_error NameError
      end
    end
  end

  describe '.build' do
    let(:ability)    { :FAKE_ABILITY }
    let(:controller) { :FAKE_CONTROLLER }

    it 'returns an instance of the form class' do
      expect(form_service.build(work, ability, controller))
        .to be_a Hyrax::GenericWorkForm
    end
  end
end
