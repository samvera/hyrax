require 'spec_helper'

RSpec.describe Hyrax::AdminSetService do
  let(:controller) { ::CatalogController.new }
  let(:context) do
    double(current_ability: Ability.new(user),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end
  let(:service) { described_class.new(context) }
  let(:user) { create(:user) }

  describe "#search_results" do
    subject { service.search_results(access) }
    let!(:as1) { create(:admin_set, :public, title: ['foo']) }
    let!(:as2) { create(:admin_set, :public, title: ['bar']) }
    let!(:as3) { create(:admin_set, edit_users: [user.user_key], title: ['baz']) }
    before do
      create(:collection, :public) # this should never be returned.
    end

    context "with read access" do
      let(:access) { :read }
      it "returns three admin sets" do
        expect(subject.map(&:id)).to match_array [as1.id, as2.id, as3.id]
      end
    end

    context "with edit access" do
      let(:access) { :edit }
      it "returns one admin set" do
        expect(subject.map(&:id)).to match_array [as3.id]
      end
    end
  end

  context "with injection" do
    let(:service) { described_class.new(context, search_builder) }
    subject { service.search_results(access) }
    let(:access) { :edit }
    let(:search_builder) { double(new: search_builder_instance) }
    let(:search_builder_instance) { double }

    it "calls the injected search builder" do
      expect(search_builder_instance).to receive(:reverse_merge).and_return({})
      subject
    end
  end

  describe '#search_results_with_work_count' do
    let(:access) { :read }
    subject { service.search_results_with_work_count(access) }
    let(:documents) { [doc1, doc2, doc3] }
    let(:doc1) { SolrDocument.new(id: 'xyz123') }
    let(:doc2) { SolrDocument.new(id: 'yyx123') }
    let(:doc3) { SolrDocument.new(id: 'zxy123') }
    let(:connection) { instance_double(RSolr::Client) }
    let(:facets) { { 'isPartOf_ssim' => [doc1.id, 8, doc2.id, 2] } }
    let(:document_list) do
      [
        {
          'isPartOf_ssim' => ['xyz123'],
          'file_set_ids_ssim' => ['aaa']
        },
        {
          'isPartOf_ssim' => ['xyz123', 'yyx123'],
          'file_set_ids_ssim' => ['bbb', 'ccc']
        }
      ]
    end

    let(:results) do
      {
        'response' =>
          {
            'docs' => document_list
          },
        'facet_counts' =>
          {
            'facet_fields' => facets
          }
      }
    end

    before do
      allow(service).to receive(:search_results).and_return(documents)
      allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(connection)
      allow(connection).to receive(:get).with("select", params: { fq: "{!terms f=isPartOf_ssim}xyz123,yyx123,zxy123",
                                                                  "facet.field" => "isPartOf_ssim" }).and_return(results)
    end

    let(:struct) { described_class::SearchResultForWorkCount }

    context "when there are works in the admin set" do
      it "returns rows with document in the first column and integer count value in the second and third column" do
        expect(subject).to eq [struct.new(doc1, 8, 3), struct.new(doc2, 2, 2), struct.new(doc3, 0, 0)]
      end
    end

    context "when there are no files in the admin set" do
      let(:document_list) do
        [
          {
            'isPartOf_ssim' => ['xyz123']
          },
          {
            'isPartOf_ssim' => ['xyz123', 'yyx123']
          }
        ]
      end
      it "returns rows with document in the first column and integer count value in the second and third column" do
        expect(subject).to eq [struct.new(doc1, 8, 0), struct.new(doc2, 2, 0), struct.new(doc3, 0, 0)]
      end
    end
  end
end
