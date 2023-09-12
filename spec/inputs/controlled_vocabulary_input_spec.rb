# frozen_string_literal: true
RSpec.describe 'ControlledVocabularyInput', type: :input do
  let(:work) { GenericWork.new }
  let(:builder) { SimpleForm::FormBuilder.new(:generic_work, work, view, {}) }
  let(:input) { ControlledVocabularyInput.new(builder, :based_near, nil, :multi_value, {}) }

  describe '#input' do
    context 'with an active fedora style value' do
      before { allow(work).to receive(:[]).with(:based_near).and_return([item1, item2]) }
      let(:item1) { double('value 1', rdf_label: ['Item 1'], rdf_subject: 'http://example.org/1', full_label: 'Item One', node?: false) }
      let(:item2) { double('value 2', rdf_label: ['Item 2'], rdf_subject: 'http://example.org/2', full_label: 'Item Two') }

      it 'renders multi-value' do
        expect(input).to receive(:build_field).with(item1, 0)
        expect(input).to receive(:build_field).with(item2, 1)
        input.input({})
      end
    end

    # sends to build_field:
    #   - "0"
    #   - Valkyrie::ID.new('https://sws.geonames.org/6255148/')
    context 'with a single valkyrie style value' do
      let(:work) do
        FactoryBot.valkyrie_create(
          :generic_work,
          based_near:
            [["0", Valkyrie::ID.new('https://sws.geonames.org/6255148/')]]
          )
      end

      it 'renders single value' do
        allow(input).to receive(:build_field).and_call_original
        input.input({})
        expect(input).to have_received(:build_field).once
      end
    end

    # sends to build_field:
    #   - ["0", Valkyrie::ID.new('https://sws.geonames.org/6255148/')]
    #   - ["1", Valkyrie::ID.new('https://sws.geonames.org/5102922/')]
    context 'with a multi-valued valkyrie style value' do
      let(:work) do
        FactoryBot.valkyrie_create(
          :generic_work,
          based_near: [
            ["0", Valkyrie::ID.new('https://sws.geonames.org/6255148/')],
            ["1", Valkyrie::ID.new('https://sws.geonames.org/5102922/')]
          ])
      end

      it 'renders multi-value' do
        allow(input).to receive(:build_field).and_call_original
        input.input({})
        expect(input).to have_received(:build_field).twice
      end
    end

    context 'with a valkyrie style value' do
      let(:work) do
        FactoryBot.valkyrie_create(
          :generic_work,
          based_near:
            [["0", Valkyrie::ID.new('https://sws.geonames.org/6255148/')]]
          )
      end

      it 'renders multi-value' do
        binding.pry
        allow(input).to receive(:build_field).and_call_original
        input.input({})
        expect(input).to have_received(:build_field).twice
      end
    end
  end

  describe '#collection' do
    let(:location) { Hyrax::ControlledVocabularies::Location.new(::RDF::URI('http://example.org/1')) }
    let(:work) { GenericWork.new(based_near: [location]) }

    subject { input }

    its(:collection) { is_expected.to all(be_an(Hyrax::ControlledVocabularies::Location)) }

    context 'with a single valued input' do
      let(:work) { FactoryBot.build(:monograph, based_near: [location]) }

      its(:collection) { is_expected.to all(be_an(Hyrax::ControlledVocabularies::Location)) }
    end
  end

  describe '#build_field' do
    subject { input.send(:build_field, value, 0) }

    context 'for a resource' do
      let(:value) { double('value 1', rdf_label: ['Item 1'], rdf_subject: 'http://example.org/1', full_label: 'Item One', node?: false) }

      it 'renders multi-value' do
        expect(subject).to have_selector('input.generic_work_based_near.multi_value')
        expect(subject).to have_field('generic_work[based_near_attributes][0][hidden_label]', with: 'Item 1')
        expect(subject).to have_selector('input[name="generic_work[based_near_attributes][0][id]"][value="http://example.org/1"]', visible: false)
        expect(subject).to have_selector('input[name="generic_work[based_near_attributes][0][_destroy]"][value=""][data-destroy]', visible: false)
        result = "<input class=\"multi_value required generic_work_based_near form-control multi-text-field\" name=\"generic_work[based_near_attributes][0][hidden_label]\" data-attribute=\"based_near\" data-label=\"Item One\" id=\"generic_work_based_near_attributes_0_hidden_label\" value=\"Item 1\" readonly=\"readonly\" aria-labelledby=\"generic_work_based_near_label\" type=\"text\" /><input name=\"generic_work[based_near_attributes][0][id]\" id=\"generic_work_based_near_attributes_0_id\" value=\"http://example.org/1\" data-id=\"remote\" autocomplete=\"off\" type=\"hidden\" /><input name=\"generic_work[based_near_attributes][0][_destroy]\" id=\"generic_work_based_near_attributes_0__destroy\" value=\"\" data-destroy=\"true\" autocomplete=\"off\" type=\"hidden\" />"
        expect(subject).to eq result
      end
    end

    context 'for a valkyrie resource' do
      let(:work) { FactoryBot.valkyrie_create(:generic_work, based_near: [["0", Valkyrie::ID.new('https://sws.geonames.org/6255148/')],
   ["1", Valkyrie::ID.new('https://sws.geonames.org/5102922/')]])}
      it 'renders the html for the value' do
        rendered = input.send(:build_field, work.based_near.first.last, 0)

        result = "<input class=\"multi_value required generic_work_based_near form-control multi-text-field\" name=\"generic_work[based_near_attributes][0][hidden_label]\" data-attribute=\"based_near\" data-label=\"Item One\" id=\"generic_work_based_near_attributes_0_hidden_label\" value=\"Item 1\" readonly=\"readonly\" aria-labelledby=\"generic_work_based_near_label\" type=\"text\" /><input name=\"generic_work[based_near_attributes][0][id]\" id=\"generic_work_based_near_attributes_0_id\" value=\"http://example.org/1\" data-id=\"remote\" autocomplete=\"off\" type=\"hidden\" /><input name=\"generic_work[based_near_attributes][0][_destroy]\" id=\"generic_work_based_near_attributes_0__destroy\" value=\"\" data-destroy=\"true\" autocomplete=\"off\" type=\"hidden\" />"
        expect(rendered).to eq result
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
        expect(options).to include(data: { attribute: :based_near, label: '', 'search-url' => '/authorities/search' })
      end
    end
  end
end
