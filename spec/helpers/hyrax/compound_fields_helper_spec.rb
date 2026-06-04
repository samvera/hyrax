# frozen_string_literal: true

RSpec.describe Hyrax::CompoundFieldsHelper, type: :helper do
  describe '#compound_subfield_options' do
    let(:spec) { { type: 'controlled', authority: nil, values: [%w[Author Author], %w[Editor ed]] } }

    it 'returns the inline values list' do
      expect(helper.compound_subfield_options(spec)).to eq([%w[Author Author], %w[Editor ed]])
    end

    it 'leaves the list unchanged when the current value is already offered' do
      expect(helper.compound_subfield_options(spec, 'ed')).to eq([%w[Author Author], %w[Editor ed]])
    end

    it 'appends a stored value that is not among the offered options' do
      expect(helper.compound_subfield_options(spec, 'Legacy'))
        .to eq([%w[Author Author], %w[Editor ed], %w[Legacy Legacy]])
    end

    it 'returns an empty list for a controlled sub-field with neither values nor authority' do
      expect(helper.compound_subfield_options({ type: 'controlled', authority: nil, values: nil })).to eq([])
    end
  end

  describe '#compound_subfield_forced?' do
    let(:spec) { { type: 'controlled', authority: nil, values: [%w[Author Author]] } }

    it 'is false when the value is blank' do
      expect(helper.compound_subfield_forced?(spec, '')).to be false
    end

    it 'is false when the value is among the offered options' do
      expect(helper.compound_subfield_forced?(spec, 'Author')).to be false
    end

    it 'is true when the value is not among the offered options' do
      expect(helper.compound_subfield_forced?(spec, 'Legacy')).to be true
    end
  end

  describe '#compound_subfield_label' do
    it 'falls back to a humanized sub-field key when no translation exists' do
      expect(helper.compound_subfield_label(:nonexistent_compound, :some_field)).to eq('Some field')
    end
  end

  describe 'card display' do
    # A schema whose only card compound is :relationships.
    let(:schema) do
      instance_double(Hyrax::CompoundSchema,
                      card?: false,
                      card_compound_names: [:relationships])
    end

    # Show presenters resolve their compound schema from the backing Solr
    # document (so flexible mode works), so stub that resolution path.
    before do
      allow(Hyrax::CompoundSchema).to receive(:for_solr_document).and_return(schema)
      allow(schema).to receive(:card?).with(:relationships).and_return(true)
      allow(schema).to receive(:card?).with(:contributors).and_return(false)
    end

    describe '#compound_card_field?' do
      let(:solr_document) { instance_double(SolrDocument, hydra_model: GenericWork) }
      let(:presenter) do
        pres = instance_double(Hyrax::WorkShowPresenter, solr_document: solr_document)
        allow(pres).to receive(:respond_to?).with(:solr_document).and_return(true)
        pres
      end

      it 'is true for a card-display compound' do
        expect(helper.compound_card_field?(presenter, :relationships)).to be true
      end

      it 'is false for an inline compound' do
        expect(helper.compound_card_field?(presenter, :contributors)).to be false
      end

      it 'is false (not raising) when the schema cannot be resolved' do
        expect(helper.compound_card_field?(Object.new, :relationships)).to be false
      end
    end

    describe '#render_compound_cards' do
      let(:solr_document) { instance_double(SolrDocument, hydra_model: GenericWork) }

      # A presenter test object that responds to `solr_document` and the
      # compound reader. A plain instance_double can't `and_call_original` on
      # `respond_to?`, and `render_compound_cards` probes the presenter with
      # `respond_to?(name)`, so build a small stand-in that answers honestly.
      def work_presenter(relationships:)
        Class.new do
          attr_reader :solr_document, :relationships
          def initialize(solr_document, relationships)
            @solr_document = solr_document
            @relationships = relationships
          end
        end.new(solr_document, relationships)
      end

      it 'renders a card for each card compound with a present value' do
        presenter = work_presenter(relationships: [{ 'related_item' => 'x' }])
        allow(helper).to receive(:render).and_return('<div class="card"></div>'.html_safe)

        expect(helper).to receive(:render)
          .with('hyrax/compounds/compound_card', presenter: presenter, field: :relationships)
        helper.render_compound_cards(presenter)
      end

      it 'skips a card compound with no value' do
        presenter = work_presenter(relationships: [])

        expect(helper).not_to receive(:render)
        expect(helper.render_compound_cards(presenter)).to eq(''.html_safe)
      end

      it 'returns an empty safe string when the class cannot be resolved' do
        expect(helper.render_compound_cards(Object.new)).to eq(''.html_safe)
      end
    end
  end
end
