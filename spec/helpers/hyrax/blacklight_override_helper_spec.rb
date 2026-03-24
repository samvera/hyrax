# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::BlacklightOverride, type: :helper do
  include Hyrax::BlacklightOverride

  let(:document) { instance_double(SolrDocument, to_h: {}) }

  def index_fields(_document)
    { 'subject_tesim' => field_config }
  end

  describe '#index_field_label' do
    context 'when custom_label is true and label is a plain string' do
      let(:field_config) { double('FieldConfig', custom_label: true, label: 'Subject') }

      it 'returns the stored string directly' do
        expect(index_field_label(document, 'subject_tesim')).to eq('Subject')
      end
    end

    context 'when custom_label is true and label is a lambda' do
      let(:field_config) do
        display_label = { 'en' => 'Subject', 'es' => 'Materia', 'default' => 'Subject' }.with_indifferent_access
        lbl = lambda { |*|
          label = display_label[I18n.locale] || display_label[:default]
          I18n.t(label, default: label)
        }
        double('FieldConfig', custom_label: true, label: lbl)
      end

      it 'calls the lambda and returns the English label for :en' do
        I18n.with_locale(:en) do
          expect(index_field_label(document, 'subject_tesim')).to eq('Subject')
        end
      end

      it 'calls the lambda and returns the Spanish label for :es' do
        I18n.with_locale(:es) do
          expect(index_field_label(document, 'subject_tesim')).to eq('Materia')
        end
      end
    end
  end
end
