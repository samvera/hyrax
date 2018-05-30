RSpec.describe "Viewing the TTL graph of a NestedWork", type: :request do
  let(:nest) do
    NamespacedWorks::NestedWork.create!(
      title: ["test"],
      created_attributes: [{ "start" => ["2000"], "finish" => ["2010"] }],
      visibility: 'open'
    )
  end

  context 'using format: :ttl' do
    it 'renders the TTL' do
      get hyrax_namespaced_works_nested_work_path(nest, format: :ttl)

      expect(response).to be_successful
      expect(response.content_type).to eq 'text/turtle'

      expect(response.body).to include "\n<http://www.example.com/concern/namespaced_works/nested_works/#{nest.id}> a "
      expect(response.body).to include "\n<http://www.example.com/concern/namespaced_works/nested_works/#{nest.id}%23timespan"

      expect(response.body).not_to include "\n<http://www.example.com/catalog/#{nest.id}> a "
      expect(response.body).not_to include "\n<http://www.example.com/catalog/#{nest.id}%23timespan"
    end
  end
end
