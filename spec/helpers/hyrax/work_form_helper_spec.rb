# frozen_string_literal: true

RSpec.describe Hyrax::WorkFormHelper do
  describe 'form_tabs_for' do
    context 'with a work form' do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::GenericWorkForm.new(work, ability, controller) }

      it 'returns a default tab list' do
        expect(form_tabs_for(form: form)).to eq ["metadata", "files", "relationships"]
      end
    end

    context 'with a batch upload form' do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::Forms::BatchUploadForm.new(work, ability, controller) }

      it 'returns an alternate tab ordering' do
        expect(form_tabs_for(form: form)).to eq ["files", "metadata", "relationships"]
      end
    end
  end

  describe 'form_progress_sections_for' do
    context 'with a work form' do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::GenericWorkForm.new(work, ability, controller) }

      it 'returns an empty list' do
        expect(form_progress_sections_for(form: form)).to eq []
      end
    end

    context 'with a batch upload form' do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::Forms::BatchUploadForm.new(work, ability, controller) }

      it 'returns an empty list' do
        expect(form_progress_sections_for(form: form)).to eq []
      end
    end
  end
end
