# frozen_string_literal: true

# Show-page rendering for a `linked_record` sub-property: the stored value (a row
# id) renders as the record's label LINKED to its show path, resolved via
# Hyrax::CompoundLinkedRecordResolver. Mirrors the `work_or_url` branch. The link
# text uses the profile's `view: { label_field: }` when present, else the
# source's registered label proc. Falls back to the bare id when unresolvable, so
# it never emits a broken link.
RSpec.describe Hyrax::Renderers::CompoundAttributeRenderer do
  let(:record) { Struct.new(:id, :full_name, :display_name).new(7, 'PROC NAME', 'Ada Lovelace') }

  around do |example|
    Hyrax::CompoundLinkedRecordResolver.register(
      :stub_people,
      finder: ->(id) { id.to_s == '7' ? record : nil },
      label: ->(r) { r.full_name },
      path: ->(r) { "/people/#{r.id}" }
    )
    example.run
  ensure
    Hyrax::CompoundLinkedRecordResolver.registry.delete(:stub_people)
  end

  context 'when the value resolves and view.label_field names a record field' do
    let(:subproperties) do
      { 'person' => { type: 'linked_record', authority: 'stub_people', label_field: 'display_name', values: nil } }
    end
    let(:values) { [{ 'person' => '7' }] }
    let(:renderer) { described_class.new(:people, values, label: 'People', html_dl: true, subproperties:) }

    it 'links the label_field value (not the registry proc) to the show path' do
      markup = renderer.render_dl_row
      expect(markup).to include('Ada Lovelace')
      expect(markup).not_to include('PROC NAME')
      expect(markup).to include('href="/people/7"')
    end
  end

  context 'when no label_field is declared' do
    let(:subproperties) do
      { 'person' => { type: 'linked_record', authority: 'stub_people', label_field: nil, values: nil } }
    end
    let(:values) { [{ 'person' => '7' }] }
    let(:renderer) { described_class.new(:people, values, label: 'People', html_dl: true, subproperties:) }

    it 'falls back to the registry label proc' do
      markup = renderer.render_dl_row
      expect(markup).to include('PROC NAME')
      expect(markup).to include('href="/people/7"')
    end
  end

  context 'when the value does not resolve' do
    let(:subproperties) do
      { 'person' => { type: 'linked_record', authority: 'stub_people', label_field: 'display_name', values: nil } }
    end
    let(:values) { [{ 'person' => '999' }] }
    let(:renderer) { described_class.new(:people, values, label: 'People', html_dl: true, subproperties:) }

    it 'renders the bare id, not a broken link' do
      markup = renderer.render_dl_row
      expect(markup).to include('999')
      expect(markup).not_to include('href="/people/999"')
    end
  end
end
