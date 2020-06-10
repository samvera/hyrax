# frozen_string_literal: true
RSpec.describe 'ControlledVocabularyInput', type: :input do
  let(:work) { GenericWork.new }
  let(:builder) { SimpleForm::FormBuilder.new(:generic_work, work, view, {}) }
  let(:input) { ControlledVocabularyInput.new(builder, :based_near, nil, :multi_value, {}) }

  describe '#input' do
    before { allow(work).to receive(:[]).with(:based_near).and_return([item1, item2]) }
    let(:item1) { double('value 1', rdf_label: ['Item 1'], rdf_subject: 'http://example.org/1', node?: false) }
    let(:item2) { double('value 2', rdf_label: ['Item 2'], rdf_subject: 'http://example.org/2') }

    it 'renders multi-value' do
      expect(input).to receive(:build_field).with(item1, 0)
      expect(input).to receive(:build_field).with(item2, 1)
      input.input({})
    end
  end

  describe '#collection' do
    let(:work) { GenericWork.new(based_near: [::RDF::URI('http://example.org/1')]) }

    subject { input.send(:collection) }

    it { is_expected.to all(be_an(Hyrax::ControlledVocabularies::Location)) }
  end

  describe '#build_field' do
    subject { input.send(:build_field, value, 0) }

    context 'for a resource' do
      let(:value) { double('value 1', rdf_label: ['Item 1'], rdf_subject: 'http://example.org/1', node?: false) }

      it 'renders multi-value' do
        expect(subject).to have_selector('input.generic_work_based_near.multi_value')
        expect(subject).to have_field('generic_work[based_near_attributes][0][hidden_label]', with: 'Item 1')
        expect(subject).to have_selector('input[name="generic_work[based_near_attributes][0][id]"][value="http://example.org/1"]', visible: false)
        expect(subject).to have_selector('input[name="generic_work[based_near_attributes][0][_destroy]"][value=""][data-destroy]', visible: false)
      end
    end
  end

  describe "#build_options" do
    subject { input.send(:build_options, value, index, options) }

    let(:value) { Hyrax::ControlledVocabularies::Location.new }
    let(:index) { 0 }
    let(:options) { {} }

    context "when data is passed" do
      let(:options) { { data: { 'search-url' => '/authorities/search' } } }

      it "preserves passed in data" do
        subject
        expect(options).to include(data: { attribute: :based_near, 'search-url' => '/authorities/search' })
      end
    end
  end
end
