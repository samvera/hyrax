RSpec.describe Hyrax::BatchEditChangeSet do
  let(:model) { GenericWork.new }
  let(:work1) do
    create_for_repository :work,
                          title: ["title 1"],
                          keyword: ["abc"],
                          creator: ["Wilma"],
                          language: ['en'],
                          contributor: ['contributor1'],
                          description: ['description1'],
                          license: ['license1'],
                          subject: ['subject1'],
                          identifier: ['id1'],
                          based_near: ['based_near1'],
                          related_url: ['related_url1']
  end
  let(:persister) { Valkyrie.config.metadata_adapter.persister }

  # Using a different work type in order to show that the form supports
  # batches containing multiple types of works
  let(:work2) do
    persister.save(resource: NamespacedWorks::NestedWork.new(title: ["title 2"],
                                                             keyword: ["123"],
                                                             creator: ["Fred"],
                                                             publisher: ['Rand McNally'],
                                                             language: ['en'],
                                                             resource_type: ['bar'],
                                                             contributor: ['contributor2'],
                                                             description: ['description2'],
                                                             license: ['license2'],
                                                             subject: ['subject2'],
                                                             identifier: ['id2'],
                                                             based_near: ['based_near2'],
                                                             related_url: ['related_url2']))
  end

  let(:batch_document_ids) { [work1.id, work2.id] }
  let(:change_set) { described_class.new(model, batch_document_ids: batch_document_ids) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }

  describe "#fields" do
    subject { change_set.fields.keys }

    it do
      is_expected.to eq ['batch_document_ids',
                         'creator',
                         'contributor',
                         'description',
                         'keyword',
                         'resource_type',
                         'license',
                         'publisher',
                         'date_created',
                         'subject',
                         'language',
                         'identifier',
                         'based_near',
                         'related_url']
    end
  end

  describe "#model" do
    it "combines the models in the batch" do
      expect(change_set.creator).to match_array ["Wilma", "Fred"]
      expect(change_set.contributor).to match_array ["contributor1", "contributor2"]
      expect(change_set.description).to match_array ["description1", "description2"]
      expect(change_set.keyword).to match_array ["abc", "123"]
      expect(change_set.resource_type).to match_array ["bar"]
      expect(change_set.license).to match_array ["license1", "license2"]
      expect(change_set.publisher).to match_array ["Rand McNally"]
      expect(change_set.subject).to match_array ["subject1", "subject2"]
      expect(change_set.language).to match_array ["en"]
      expect(change_set.identifier).to match_array ["id1", "id2"]
      expect(change_set.based_near).to match_array ["based_near1", "based_near2"]
      expect(change_set.related_url).to match_array ["related_url1", "related_url2"]
    end
  end
end
