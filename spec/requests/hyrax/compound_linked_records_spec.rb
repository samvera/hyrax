# frozen_string_literal: true

# The generic inline-create endpoint for a `linked_record` picker's
# lookup-or-create flow: POST /linked_records/:source creates a record via the
# registered source and returns { id:, label: } JSON (201), the record's errors
# (422), or 404 when the source is unknown / not creatable. Source-agnostic — it
# routes by the :source segment to whatever Hyrax::CompoundLinkedRecordResolver
# has registered. Driven here through an in-memory stub source.
RSpec.describe 'Hyrax linked_record create endpoint', type: :request do
  # A minimal in-memory record + store the stub source creates into. `ids`
  # captures a `group` create-field so a test can assert its shape.
  let(:store) { {} }
  let(:record_class) { Struct.new(:id, :display_name, :ids, :affiliations, :persisted?, :errors, keyword_init: true) }

  before do
    s = store
    rc = record_class
    Hyrax::CompoundLinkedRecordResolver.register(
      :stub_people,
      finder: ->(id) { s[id.to_s] },
      label: ->(r) { r.display_name },
      path: ->(r) { "/stub_people/#{r.id}" },
      create: lambda { |attrs|
        name = attrs[:display_name].to_s
        if name.empty?
          rc.new(id: nil, display_name: name, ids: nil, affiliations: nil, persisted?: false, errors: ['Display name is required'])
        else
          id = (s.size + 1).to_s
          rec = rc.new(id:, display_name: name, ids: attrs[:ids], affiliations: attrs[:affiliations], persisted?: true, errors: [])
          s[id] = rec
          rec
        end
      }
    )
  end

  after { Hyrax::CompoundLinkedRecordResolver.registry.delete(:stub_people) }

  describe 'POST /linked_records/:source' do
    it 'creates a record and returns { id, label } as 201' do
      post hyrax.compound_linked_record_path(source: 'stub_people'),
           params: { record: { display_name: 'Grace Hopper' } }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body['label']).to eq('Grace Hopper')
      expect(store[body['id'].to_s].display_name).to eq('Grace Hopper')
    end

    it 'returns 422 with errors when creation is invalid' do
      post hyrax.compound_linked_record_path(source: 'stub_people'),
           params: { record: { display_name: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to be_present
    end

    it 'returns 404 for an unknown / non-creatable source' do
      post hyrax.compound_linked_record_path(source: 'nonexistent'),
           params: { record: { display_name: 'X' } }

      expect(response).to have_http_status(:not_found)
    end

    it 'passes a group create-field through to the proc as a deep-symbolized array of hashes' do
      post hyrax.compound_linked_record_path(source: 'stub_people'),
           params: { record: { display_name: 'Grace Hopper',
                               ids: [{ value: '0000000121032683', scheme: 'ISNI' },
                                     { value: 'https://ror.org/02mhbdp94', scheme: 'ROR' }] } }

      expect(response).to have_http_status(:created)
      created = store[response.parsed_body['id'].to_s]
      expect(created.ids).to eq(
        [{ value: '0000000121032683', scheme: 'ISNI' },
         { value: 'https://ror.org/02mhbdp94', scheme: 'ROR' }]
      )
    end

    it 'passes a repeatable scalar create-field through as a plain array of strings' do
      post hyrax.compound_linked_record_path(source: 'stub_people'),
           params: { record: { display_name: 'Grace Hopper',
                               affiliations: ['US Navy', 'Vassar College'] } }

      expect(response).to have_http_status(:created)
      created = store[response.parsed_body['id'].to_s]
      expect(created.affiliations).to eq(['US Navy', 'Vassar College'])
    end
  end
end
