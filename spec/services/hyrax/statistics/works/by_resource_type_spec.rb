# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::Works::ByResourceType do
  let(:service) { described_class.new }
  let(:user) { create(:user) }

  describe "#query", :clean_repo do
    before do
      if Hyrax.config.use_valkyrie?
        FactoryBot.valkyrie_create(:monograph, title: ['test 1'], resource_type: ['Conference Proceeding'])
        FactoryBot.valkyrie_create(:monograph, title: ['test 2'], resource_type: ['Conference Proceeding'])
        FactoryBot.valkyrie_create(:monograph, title: ['test 3'], resource_type: ['Image'])
        FactoryBot.valkyrie_create(:monograph, title: ['test 4'], resource_type: ['Journal'])
      else
        GenericWork.create(title: ['test 1'], resource_type: ['Conference Proceeding']).save!
        GenericWork.create(title: ['test 2'], resource_type: ['Conference Proceeding']).save!
        GenericWork.create(title: ['test 3'], resource_type: ['Image']).save!
        GenericWork.create(title: ['test 4'], resource_type: ['Journal']).save!
      end
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
