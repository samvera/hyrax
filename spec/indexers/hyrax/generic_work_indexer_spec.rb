# frozen_string_literal: true
RSpec.describe GenericWorkIndexer, :active_fedora do
  subject(:solr_document) { service.generate_solr_document }

  # TODO: file_set_ids returns an empty set unless you persist the work
  let(:user) { create(:user) }
  let(:service) { described_class.new(work) }
  let(:work) { create(:generic_work) }

  context 'without explicit visibility set' do
    it 'indexes visibility' do
      expect(solr_document['visibility_ssi']).to eq 'restricted' # tight default
    end
  end

  context 'with explicit visibility set' do
    before { allow(work).to receive(:visibility).and_return('authenticated') }
    it 'indexes visibility' do
      expect(solr_document['visibility_ssi']).to eq 'authenticated'
    end
  end

  context "with child works" do
    let!(:work) { create(:work_with_one_file, user: user) }
    let!(:child_work) { create(:generic_work, user: user) }
    let(:file) { work.file_sets.first }

    before do
      work.works << child_work
      allow(Hyrax::ThumbnailPathService).to receive(:call).and_return("/downloads/#{file.id}?file=thumbnail")
      work.representative_id = file.id
      work.thumbnail_id = file.id
    end

    it 'indexes member work and file_set ids' do
      expect(solr_document['member_ids_ssim']).to eq work.member_ids
      expect(solr_document['generic_type_sim']).to eq ['Work']
      expect(solr_document.fetch('thumbnail_path_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
      expect(subject.fetch('hasRelatedImage_ssim').first).to eq file.id
      expect(subject.fetch('hasRelatedMediaFragment_ssim').first).to eq file.id
    end

    context "when thumbnail_field is configured" do
      before do
        service.thumbnail_field = 'thumbnail_url_ss'
      end
      it "uses the configured field" do
        expect(solr_document.fetch('thumbnail_url_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
      end
    end
  end

  context "with an AdminSet" do
    let(:work) { create(:generic_work, admin_set: admin_set) }
    let(:admin_set) { create(:admin_set, title: ['Title One']) }

    it "indexes the correct fields" do
      expect(solr_document.fetch('admin_set_sim')).to eq ["Title One"]
      expect(solr_document.fetch('admin_set_tesim')).to eq ["Title One"]
    end
  end

  context "the object status" do
    before { allow(work).to receive(:suppressed?).and_return(suppressed) }
    context "when suppressed" do
      let(:suppressed) { true }

      it "indexes the suppressed field with a true value" do
        expect(solr_document.fetch('suppressed_bsi')).to be true
      end
    end

    context "when not suppressed" do
      let(:suppressed) { false }

      it "indexes the suppressed field with a false value" do
        expect(solr_document.fetch('suppressed_bsi')).to be false
      end
    end
  end

  context "the actionable workflow roles" do
    let(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    before do
      allow(Sipity).to receive(:Entity).with(work).and_return(sipity_entity)
      allow(Hyrax::Workflow::PermissionQuery).to receive(:scope_roles_associated_with_the_given_entity)
        .and_return(['approve', 'reject'])
    end
    it "indexed the roles and state" do
      expect(solr_document.fetch('actionable_workflow_roles_ssim')).to eq [
        "#{sipity_entity.workflow.permission_template.source_id}-#{sipity_entity.workflow.name}-approve",
        "#{sipity_entity.workflow.permission_template.source_id}-#{sipity_entity.workflow.name}-reject"
      ]
      expect(solr_document.fetch('workflow_state_name_ssim')).to eq "initial"
    end
  end

  describe "with a remote resource (based near)" do
    # You can get the original RDF+XML here:
    # https://sws.geonames.org/5037649/about.rdf Note: in this RDF+XML
    # document, the only "English readable" identifying attributes are
    # the nodes: `gn:name` and `gn:countryCode`.  In other words the
    # helpful administrative container (e.g. Minnesota) is not in this
    # document.
    mpls = <<RDFXML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <rdf:RDF xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:gn="http://www.geonames.org/ontology#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
          <gn:Feature rdf:about="http://sws.geonames.org/5037649/">
          <gn:name>Minneapolis</gn:name>
          <gn:countryCode>US</gn:countryCode>
          </gn:Feature>
          </rdf:RDF>
RDFXML

    before do
      allow(service).to receive(:rdf_service).and_return(Hyrax::DeepIndexingService)
      work.based_near_attributes = [{ id: 'http://sws.geonames.org/5037649/' }]

      stub_request(:get, "http://sws.geonames.org/5037649/")
        .to_return(status: 200, body: mpls,
                   headers: { 'Content-Type' => 'application/rdf+xml;charset=UTF-8' })

      stub_request(:get, 'http://www.geonames.org/getJSON')
        .with(query: hash_including({ 'geonameId': '5037649' }))
        .to_return(status: 200, body: File.open(File.join(fixture_path, 'geonames.json')))
    end

    it "indexes id and label" do
      expect(solr_document.fetch('based_near_sim')).to eq ["http://sws.geonames.org/5037649/"]
      expect(solr_document.fetch('based_near_label_sim')).to eq ["Minneapolis, Minnesota, United States"]
    end
  end
end
