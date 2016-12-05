require 'spec_helper'

describe CurationConcerns::WorkIndexer do
  # TODO: file_set_ids returns an empty set unless you persist the work
  let(:user) { create(:user) }
  let(:service) { described_class.new(work) }
  subject(:solr_document) { service.generate_solr_document }
  let(:work) { create(:generic_work) }

  context "with child works" do
    let!(:work) { create(:work_with_one_file, user: user) }
    let!(:child_work) { create(:generic_work, user: user) }
    let(:file) { work.file_sets.first }

    before do
      work.works << child_work
      allow(CurationConcerns::ThumbnailPathService).to receive(:call).and_return("/downloads/#{file.id}?file=thumbnail")
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

  describe 'suppressed state' do
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
    let!(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end
    before do
      allow(PowerConverter).to receive(:convert_to_sipity_entity).with(work).and_return(sipity_entity)
      allow(CurationConcerns::Workflow::PermissionQuery).to receive(:scope_roles_associated_with_the_given_entity)
        .and_return(['approve', 'reject'])
    end
    it "indexed the roles and state" do
      expect(solr_document.fetch('actionable_workflow_roles_ssim')).to eq ["#{sipity_entity.workflow.name}-approve", "#{sipity_entity.workflow.name}-reject"]
      expect(solr_document.fetch('workflow_state_name_ssim')).to eq "initial"
    end
  end
end
