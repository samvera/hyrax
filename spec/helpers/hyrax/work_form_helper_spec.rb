# frozen_string_literal: true

RSpec.describe Hyrax::WorkFormHelper do
  describe '.form_tabs_for' do
    context 'with a change set style form' do
      let(:work) { build(:hyrax_work) }
      let(:form) { Hyrax::Forms::ResourceForm.for(work) }

      it 'returns a default tab list' do
        expect(form_tabs_for(form: form)).to eq ["metadata", "files", "relationships"]
      end
    end

    context 'with a legacy GenericWork form' do
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

  describe '.form_progress_sections_for' do
    context 'with a change set style form' do
      let(:work) { build(:hyrax_work) }
      let(:form) { Hyrax::Forms::ResourceForm.for(work) }

      it 'returns an empty list' do
        expect(form_progress_sections_for(form: form)).to eq []
      end
    end

    context 'with a legacy GenericWork form' do
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

  describe '.form_file_set_select_for' do
    context 'with a legacy GenericWork form' do
      let(:work) { stub_model(GenericWork, id: '456', member_ids: file_set_ids) }
      let(:ability) { double }
      let(:file_set_ids) { [] }
      let(:form) { Hyrax::GenericWorkForm.new(work, ability, controller) }

      it 'returns an empty hash' do
        expect(form_file_set_select_for(parent: form)).to eq({})
      end

      context 'with file_set members' do
        let(:file_set_ids) { file_sets.map(&:id) }

        let(:file_sets) do
          [FactoryBot.create(:file_set, label: 'moomin.jpg'),
           FactoryBot.create(:file_set, label: 'snork.jpg')]
        end

        it 'gives labels => ids' do
          expect(form_file_set_select_for(parent: form))
            .to include('moomin.jpg' => an_instance_of(String),
                        'snork.jpg' => an_instance_of(String))
        end
      end
    end
  end
end
