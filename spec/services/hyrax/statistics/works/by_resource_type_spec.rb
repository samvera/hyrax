RSpec.describe Hyrax::Statistics::Works::ByResourceType do
  let(:service) { described_class.new }
  let(:user) { create(:user) }

  describe "#query", :clean_repo do
    before do
      # Creating factories here led to failures found within
      # https://travis-ci.org/samvera/hyrax/jobs/454752377
      # One should be able to invoke create(:generic_work)...
      # ...however, there are difficulties here which relate to the "terms"
      # requestHandler
      # @see https://github.com/samvera/hyrax/issues/3491
      GenericWork.create(title: ['test'], resource_type: ['Conference Proceeding']).save!
      GenericWork.create(title: ['test'], resource_type: ['Conference Proceeding']).save!
      GenericWork.create(title: ['test'], resource_type: ['Image']).save!
      GenericWork.create(title: ['test'], resource_type: ['Journal']).save!
    end

    subject { service.query }

    it "is a list of categories" do
      expect(subject).to eq [{ label: 'Conference Proceeding', data: 2 },
                             { label: 'Image', data: 1 },
                             { label: 'Journal', data: 1 }]
      expect(subject.to_json).to eq "[{\"label\":\"Conference Proceeding\",\"data\":2},{\"label\":\"Image\",\"data\":1},{\"label\":\"Journal\",\"data\":1}]"
    end
  end
end
