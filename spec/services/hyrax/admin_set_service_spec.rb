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
    let(:results) do
      {
        'response' =>
          {
            'docs' =>
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
          },
        'facet_counts' =>
          {
            'facet_fields' =>
              {
                'isPartOf_ssim' => [doc1.id, 8, doc2.id, 2]
              }
          }
      }
    end

    before do
      allow(service).to receive(:search_results).and_return(documents)
      allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(connection)
      allow(connection).to receive(:get).with("select", params: { fq: "{!terms f=isPartOf_ssim}xyz123,yyx123,zxy123",
                                                                  "facet.field" => "isPartOf_ssim" }).and_return(results)
    end

    it "returns rows with document in the first column and integer count value in the second and third column" do
      expect(subject).to eq [[doc1, 8, 3], [doc2, 2, 2], [doc3, 0, 0]]
    end
  end

  describe "#select_options" do
    subject { service.select_options }

    context "with permission_template visibility" do
      let(:solr_doc1) { instance_double(SolrDocument, id: '123', to_s: 'Public Set') }
      let(:solr_doc2) { instance_double(SolrDocument, id: '345', to_s: 'Private Set') }
      let!(:permission_template1) { create(:permission_template, admin_set_id: '123', visibility: 'open') }
      let!(:permission_template2) { create(:permission_template, admin_set_id: '345', visibility: 'restricted') }

      before do
        allow(service).to receive(:search_results)
          .with(:read)
          .and_return([solr_doc1, solr_doc2])
      end

      it do
        is_expected.to eq [['Public Set', '123', { 'data-visibility' => 'open' }],
                           ['Private Set', '345', { 'data-visibility' => 'restricted' }]]
      end
    end

    context "with permission_template release_date" do
      let(:today) { Time.zone.today }
      let(:solr_doc1) { instance_double(SolrDocument, id: '123', to_s: 'Fixed Release Date Set') }
      let(:solr_doc2) { instance_double(SolrDocument, id: '345', to_s: 'No Delay Set') }
      let(:solr_doc3) { instance_double(SolrDocument, id: '567', to_s: 'One Year Max Embargo Set') }
      let(:solr_doc4) { instance_double(SolrDocument, id: '789', to_s: 'Release Before Date Set') }
      let!(:permission_template1) { create(:permission_template, admin_set_id: '123', release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: today + 2.days) }
      let!(:permission_template2) { create(:permission_template, admin_set_id: '345', release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY) }
      let!(:permission_template3) { create(:permission_template, admin_set_id: '567', release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR) }
      let!(:permission_template4) { create(:permission_template, admin_set_id: '789', release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today + 1.month) }

      before do
        allow(service).to receive(:search_results)
          .with(:read)
          .and_return([solr_doc1, solr_doc2, solr_doc3, solr_doc4])
      end

      it do
        is_expected.to eq [['Fixed Release Date Set', '123', { 'data-release-date' => today + 2.days }],
                           ['No Delay Set', '345', { 'data-release-date' => today }],
                           ['One Year Max Embargo Set', '567', { 'data-release-date' => today + 1.year, 'data-release-before-date' => true }],
                           ['Release Before Date Set', '789', { 'data-release-date' => today + 1.month, 'data-release-before-date' => true }]]
      end
    end

    context "with empty permission_template" do
      let(:solr_doc1) { instance_double(SolrDocument, id: '123', to_s: 'Empty Template Set') }
      let!(:permission_template1) { create(:permission_template, admin_set_id: solr_doc1.id) }

      before do
        allow(service).to receive(:search_results).with(:read).and_return([solr_doc1])
      end

      it { is_expected.to eq [['Empty Template Set', '123', {}]] }
    end

    context "with no permission_template" do
      let(:solr_doc1) { instance_double(SolrDocument, id: '123', to_s: 'foo') }
      before do
        allow(service).to receive(:search_results).with(:read).and_return([solr_doc1])
      end
      it 'will an raise exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
