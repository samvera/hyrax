# frozen_string_literal: true

RSpec.describe Hyrax::Renderers::CompoundAttributeRenderer do
  let(:values) do
    [{ 'title' => 'Dr', 'agent_name' => 'Ada Lovelace', 'agent_role' => 'Author' },
     { 'agent_name' => 'Alan Turing' }]
  end
  let(:renderer) { described_class.new(:agent, values, label: 'Agent', html_dl: true) }

  describe '#render_dl_row' do
    subject(:markup) { renderer.render_dl_row }

    it 'renders the field label' do
      expect(markup).to include('<dt>Agent</dt>')
    end

    it 'renders one entry block per value' do
      expect(markup.scan('class="hyrax-compound-entry"').count).to eq(2)
    end

    it 'renders each populated sub-property as a labeled value' do
      expect(markup).to include('Ada Lovelace').and include('Author')
      expect(markup).to include('Alan Turing')
    end

    it 'uses the i18n sub-property labels (humanized fallback)' do
      # `title` has no compound_fields.agent.title key in the engine locale by
      # default for an arbitrary compound, so it humanizes; agent_name maps to
      # the shipped label "Name".
      expect(markup).to include('Dr')
    end

    it 'does not use <dl>/<dt>/<dd> for entries (avoids inheriting metadata dividers)' do
      entries = markup.split('hyrax-compound-values').last
      expect(entries).not_to include('<dt')
      expect(entries).not_to include('<dd')
    end

    it 'omits blank sub-properties' do
      # The second entry has only agent_name; it should not emit empty subproperty blocks.
      second_entry = markup.split('hyrax-compound-entry').last
      expect(second_entry.scan('hyrax-compound-subproperty"').count).to eq(1)
    end
  end

  describe 'empty handling' do
    it 'renders nothing for all-blank entries without include_empty' do
      r = described_class.new(:agent, [{ 'agent_name' => '' }], label: 'Agent', html_dl: true)
      expect(r.render_dl_row).to eq('')
    end
  end

  describe '#render (table row)' do
    it 'renders a table row with the label and entries' do
      markup = described_class.new(:agent, values, label: 'Agent').render
      expect(markup).to include('<th>Agent</th>')
      expect(markup).to include('Ada Lovelace')
    end
  end

  describe 'controlled sub-property term translation' do
    let(:values) { [{ 'role' => 'ed', 'name' => 'Ada' }] }
    let(:subproperties) do
      { 'role' => { type: 'controlled', authority: nil, values: [%w[Author author], %w[Editor ed]] },
        'name' => { type: 'string', authority: nil, values: nil } }
    end
    let(:renderer) { described_class.new(:agent, values, label: 'Agent', html_dl: true, subproperties: subproperties) }

    it 'displays the controlled term, not the stored id' do
      markup = renderer.render_dl_row
      expect(markup).to include('Editor')
      expect(markup).not_to match(/>ed</)
    end

    it 'leaves non-controlled sub-properties unchanged' do
      expect(renderer.render_dl_row).to include('Ada')
    end

    it 'renders the raw id when no subproperties specs are provided' do
      markup = described_class.new(:agent, values, label: 'Agent', html_dl: true).render_dl_row
      expect(markup).to include('ed')
    end
  end

  describe 'controlled sub-property with a linkable URI value' do
    let(:uri) { 'http://rightsstatements.org/vocab/InC/1.0/' }
    let(:values) { [{ 'rights_statement' => uri }] }
    let(:subproperties) do
      { 'rights_statement' => { type: 'controlled', authority: 'rights_statements', values: nil } }
    end
    let(:renderer) { described_class.new(:compound_rights, values, label: 'Rights', html_dl: true, subproperties: subproperties) }

    before do
      allow(Hyrax::CompoundSubpropertyLabeler).to receive(:label_for)
        .with(subproperties['rights_statement'], uri).and_return('In Copyright')
    end

    it 'links the resolved term to its URI' do
      markup = renderer.render_dl_row
      expect(markup).to include(%(<a href="#{uri}" target="_blank" rel="noopener noreferrer">In Copyright</a>))
    end
  end

  describe 'url sub-property auto-linking' do
    let(:values) { [{ 'related_item_url' => 'https://example.org/item/42', 'note' => 'see also' }] }
    let(:subproperties) do
      { 'related_item_url' => { type: 'url', authority: nil, values: nil },
        'note' => { type: 'string', authority: nil, values: nil } }
    end
    let(:renderer) { described_class.new(:relationships, values, label: 'Relationships', html_dl: true, subproperties: subproperties) }

    it 'renders a url sub-property as an anchor' do
      expect(renderer.render_dl_row).to include('<a href="https://example.org/item/42"')
    end

    it 'leaves non-url sub-properties as plain escaped text' do
      markup = renderer.render_dl_row
      expect(markup).to include('see also')
      expect(markup).not_to include('<a href="see also"')
    end
  end

  describe 'work_or_url sub-property' do
    let(:subproperties) { { 'related_item' => { type: 'work_or_url', authority: nil, values: nil } } }

    context 'when the value is an external URL' do
      let(:values) { [{ 'related_item' => 'https://example.org/x' }] }
      let(:renderer) { described_class.new(:relationships, values, label: 'Relationships', html_dl: true, subproperties: subproperties) }

      it 'auto-links the URL' do
        expect(renderer.render_dl_row).to include('<a href="https://example.org/x"')
      end
    end

    context 'when the value resolves to an indexed work' do
      let(:values) { [{ 'related_item' => 'work-123' }] }
      let(:renderer) { described_class.new(:relationships, values, label: 'Relationships', html_dl: true, subproperties: subproperties) }

      before do
        allow(Hyrax::CompoundWorkResolver).to receive(:resolve)
          .with('work-123').and_return(['Linked Work', '/catalog/work-123'])
      end

      it 'links to the work show path with its title' do
        markup = renderer.render_dl_row
        expect(markup).to include('href="/catalog/work-123"')
        expect(markup).to include('Linked Work')
      end
    end

    context 'when the value is neither a URL nor a resolvable work' do
      let(:values) { [{ 'related_item' => 'not-a-real-id' }] }
      let(:renderer) { described_class.new(:relationships, values, label: 'Relationships', html_dl: true, subproperties: subproperties) }

      before { allow(Hyrax::CompoundWorkResolver).to receive(:resolve).with('not-a-real-id').and_return(nil) }

      it 'renders the value as plain text without a link' do
        markup = renderer.render_dl_row
        expect(markup).to include('not-a-real-id')
        expect(markup).not_to include('<a href')
      end
    end
  end
end
