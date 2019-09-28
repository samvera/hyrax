# frozen_string_literal: true

RSpec.describe Hyrax::WorkFormService do
  describe '.build' do
    shared_examples 'a form builder' do
      let(:ability)    { :FAKE_ABILITY }
      let(:controller) { :FAKE_CONTROLLER }

      it 'builds an instance of the class' do
        expect(described_class.build(work, ability, controller))
          .to be_a described_class.form_class(work)
      end
    end

    context 'with ActiveFedora' do
      let(:work) { FactoryBot.build(:generic_work) }

      it_behaves_like 'a form builder'
    end

    context 'with valkyrie' do
      let(:work) { FactoryBot.build(:hyrax_work) }

      it_behaves_like 'a form builder'
    end
  end

  describe '.form_class' do
    context 'with ActiveFedora' do
      let(:work) { FactoryBot.build(:generic_work) }

      it 'builds the form class from a string' do
        expect(described_class.form_class(work)).to eq Hyrax::GenericWorkForm
      end
    end

    context 'with valkyrie' do
      let(:work) { FactoryBot.build(:hyrax_work) }

      it 'produces a form class' do
        expect(described_class.form_class(work)).to eq Hyrax::Forms::ChangeSetForm
      end
    end
  end
end
