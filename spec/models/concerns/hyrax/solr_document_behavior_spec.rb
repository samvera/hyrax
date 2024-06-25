# frozen_string_literal: true

RSpec.describe Hyrax::SolrDocumentBehavior do
  subject(:solr_document) { solr_document_class.new(solr_hash) }
  let(:solr_hash) { {} }

  let(:solr_document_class) do
    Class.new do
      include Blacklight::Solr::Document
      include Hyrax::SolrDocumentBehavior
    end
  end

  describe '#to_partial_path' do
    context 'with an ActiveFedora model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWork' } }

      it 'resolves the correct model name' do
        expect(solr_document.to_model.to_partial_path).to eq 'hyrax/generic_works/generic_work'
      end
    end

    context 'with a Valkyrie model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'Monograph' } }

      it 'resolves the correct model name' do
        expect(solr_document.to_model.to_partial_path).to eq 'hyrax/monographs/monograph'
      end
    end

    context 'with a Wings model name', :active_fedora do
      let(:solr_hash) { { 'has_model_ssim' => 'Wings(Monograph)' } }

      it 'gives an appropriate generated ActiveFedora class' do
        expect(solr_document.to_model.to_partial_path).to eq 'hyrax/monographs/monograph'
      end
    end

    context 'with Hyrax::PcdmCollection' do
      let(:solr_hash) { { 'has_model_ssim' => 'Hyrax::PcdmCollection' } }

      it 'resolves to collection path' do
        expect(solr_document.to_model.to_partial_path).to eq 'hyrax/collections/collection'
      end
    end
  end

  describe '#hydra_model' do
    it 'gives ActiveFedora::Base by default' do
      expect(solr_document.hydra_model).to eq ActiveFedora::Base
    end

    context 'with an ActiveFedora model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWork' } }

      it 'resolves the correct model name' do
        expect(solr_document.hydra_model.to_s).to match('GenericWork')
      end
    end

    context 'with a Valkyrie model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'Monograph' } }

      it 'resolves the correct model name' do
        expect(solr_document.hydra_model).to eq Monograph
      end

      context 'using non-wings adapter', valkyrie_adapter: :test_adapter do
        it 'does not call Wings' do
          expect(solr_document.hydra_model).to eq Monograph
        end
      end
    end

    context 'with a Wings model name', :active_fedora do
      let(:solr_hash) { { 'has_model_ssim' => 'Wings(Monograph)' } }

      it 'gives an appropriate generated ActiveFedora class' do
        expect(solr_document.hydra_model.inspect).to eq 'Wings(Monograph)'
      end
    end
  end

  describe '#itemtype' do
    it 'defaults to CreativeWork' do
      expect(solr_document.itemtype).to eq 'http://schema.org/CreativeWork'
    end

    context 'for a Video' do
      let(:solr_hash) { { resource_type_tesim: 'Video' } }

      it 'is of type Video' do
        expect(solr_document.itemtype).to eq 'http://schema.org/VideoObject'
      end
    end
  end

  describe '#title_or_label' do
    it 'defaults to nil' do
      expect(solr_document.title_or_label).to be_nil
    end

    context 'with a label' do
      let(:solr_hash) { { label_tesim: 'label' } }

      it 'gives the label' do
        expect(solr_document.title_or_label).to eq 'label'
      end
    end

    context 'with a title' do
      let(:solr_hash) { { title_tesim: 'title' } }

      it 'gives the title' do
        expect(solr_document.title_or_label).to eq 'title'
      end

      context 'and a label' do
        let(:solr_hash) { { title_tesim: 'title', label_tesim: 'label' } }

        it 'gives the title' do
          expect(solr_document.title_or_label).to eq 'title'
        end
      end
    end

    context 'with several titles' do
      let(:solr_hash) { { title_tesim: ['title1', 'title2'] } }

      it 'gives the title' do
        expect(solr_document.title_or_label).to eq 'title1, title2'
      end
    end
  end

  describe '#to_model' do
    it 'defaults to a wrapped ActiveFedora::Base' do
      expect(solr_document.to_model.model_name.to_s).to eq 'ActiveFedora::Base'
    end

    context 'with an ActiveFedora model name that converts to a resource' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWork' } }

      it 'wraps the specified model' do
        expect(solr_document.to_model.model_name.to_s).to match 'GenericWork'
      end
    end

    context 'with a Valkyrie model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'Monograph' } }

      it 'resolves the correct model name' do
        expect(solr_document.to_model.model_name.to_s).to eq 'Monograph'
      end
    end

    context 'with a Wings model name', :active_fedora do
      let(:solr_hash) { { 'has_model_ssim' => 'Wings(Monograph)', 'id' => '123' } }

      it 'gives the original valkyrie class' do
        expect(solr_document.to_model.model_name.to_s).to eq 'Monograph'
      end

      it 'gives the global id for the valkyrie class' do
        expect(solr_document.to_model.to_global_id.to_s).to end_with('Hyrax::ValkyrieGlobalIdProxy/123')
      end
    end
  end

  describe '#to_s' do
    it 'defaults to empty string' do
      expect(solr_document.to_s).to eq ''
    end
  end

  describe '#visibility' do
    context 'when an embargo is enforced' do
      let(:solr_hash) do
        { "embargo_release_date_dtsi" => "2023-08-30T00:00:00Z",
          "visibility_during_embargo_ssim" => "restricted",
          "visibility_after_embargo_ssim" => "open",
          "visibility_ssi" => "restricted" }
      end

      it 'is "embargo"' do
        expect(solr_document.visibility).to eq "embargo"
      end
    end

    context 'when an embargo is released' do
      let(:solr_hash) do
        { "embargo_release_date_dtsi" => "2023-08-30T00:00:00Z",
          "visibility_during_embargo_ssim" => "restricted",
          "visibility_after_embargo_ssim" => "open",
          "visibility_ssi" => "authenticated", # expect this to be ignored
          "read_access_group_ssim" => ["public"] }
      end

      it 'is based on the read groups and Ability behavior' do
        expect(solr_document.visibility).to eq "open"
      end
    end

    # this is a special case because some of the older Hyrax tests
    # expected this situation to work. Both ActiveFedora and Valkyrie
    # actually index the whole embargo structure.
    context 'when only an embargo date is indexed' do
      let(:solr_hash) do
        { "embargo_release_date_dtsi" => "2023-08-30T00:00:00Z" }
      end

      it 'is "embargo"' do
        expect(solr_document.visibility).to eq "embargo"
      end
    end

    context 'when an lease is enforced' do
      let(:solr_hash) do
        { "lease_expiration_date_dtsi" => "2023-08-30T00:00:00Z",
          "visibility_during_lease_ssim" => "open",
          "visibility_after_lease_ssim" => "restricted",
          "visibility_ssi" => "open" }
      end

      it 'is "lease"' do
        expect(solr_document.visibility).to eq "lease"
      end
    end

    context 'when an lease is released' do
      let(:solr_hash) do
        { "lease_expiration_date_dtsi" => "2023-08-30T00:00:00Z",
          "visibility_during_lease_ssim" => "authenticated",
          "visibility_after_lease_ssim" => "restricted",
          "visibility_ssi" => "restricted", # expect this to be ignored
          "read_access_group_ssim" => ["public"] }
      end

      it 'is based on the read groups and Ability behavior' do
        expect(solr_document.visibility).to eq "open"
      end
    end

    # this is a special case because some of the older Hyrax tests
    # expected this situation to work. Both ActiveFedora and Valkyrie
    # actually index the whole embargo structure.
    context 'when only an lease date is indexed' do
      let(:solr_hash) do
        { "lease_expiration_date_dtsi" => "2023-08-30T00:00:00Z" }
      end

      it 'is "lease"' do
        expect(solr_document.visibility).to eq "lease"
      end
    end
  end

  describe '#valkyrie?' do
    subject { solr_document.valkyrie? }

    context 'when valkyrie_bsi is present in the document and false' do
      let(:solr_hash) { { "valkyrie_bsi" => false } }
      it { is_expected.to be_falsey }
    end

    context 'when valkyrie_bsi is present in the document and true' do
      let(:solr_hash) { { "valkyrie_bsi" => true } }
      it { is_expected.to be_truthy }
    end

    context 'when valkyrie_bsi is not present in the document' do
      let(:solr_hash) { {} }
      it { is_expected.to be_falsey }
    end
  end
end
