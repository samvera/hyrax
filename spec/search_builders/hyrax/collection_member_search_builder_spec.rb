# frozen_string_literal: true
RSpec.describe Hyrax::CollectionMemberSearchBuilder do
  subject(:builder) { described_class.new(scope: context, collection: collection, search_includes_models: include_models) }
  let(:context) { double("context", blacklight_config: CatalogController.blacklight_config) }
  let(:solr_params) { { fq: [] } }
  let(:include_models) { :both }
  let(:collection) { build(:collection_lw, id: '12345') }

  describe ".default_processor_chain" do
    subject { builder.default_processor_chain }

    it { is_expected.to include :member_of_collection }
    it { is_expected.to include :filter_models }
  end

  context 'with a valkyrie collection' do
    let(:collection) { build(:hyrax_collection, id: '12345') }

    describe '#member_of_collection' do
      it 'updates solr_parameters[:fq]' do
        expect { builder.member_of_collection(solr_params) }
          .to change { solr_params[:fq] }
          .to include("#{builder.collection_membership_field}:#{collection.id}")
      end
    end

    describe '#filter_models' do
      it 'updates solr_parameters[:fq] to include both works and collections' do
        expect { builder.filter_models(solr_params) }
          .to change { solr_params[:fq].first }
          .to include('f=has_model_ssim', 'GenericWork', 'Collection')
      end

      context 'when limiting to works' do
        let(:include_models) { :works }

        it 'updates solr_parameters[:fq] to include only works' do
          expect { builder.filter_models(solr_params) }
            .to change { solr_params[:fq].first }
            .to include('f=has_model_ssim', 'GenericWork')
        end
      end

      context 'when limiting to collections' do
        let(:include_models) { :collections }

        it 'updates solr_parameters[:fq] to include only collections' do
          expect { builder.filter_models(solr_params) }
            .to change { solr_params[:fq].first }
            .to include('f=has_model_ssim', 'Collection')
        end
      end
    end
  end

  describe '#member_of_collection' do
    it 'updates solr_parameters[:fq]' do
      expect { builder.member_of_collection(solr_params) }
        .to change { solr_params[:fq] }
        .to include("#{builder.collection_membership_field}:#{collection.id}")
    end
  end

  describe '#filter_models' do
    it 'updates solr_parameters[:fq] to include both works and collections' do
      expect { builder.filter_models(solr_params) }
        .to change { solr_params[:fq].first }
        .to include('f=has_model_ssim', 'GenericWork', 'Collection')
    end

    context 'when limiting to works' do
      let(:include_models) { :works }

      it 'updates solr_parameters[:fq] to include only works' do
        expect { builder.filter_models(solr_params) }
          .to change { solr_params[:fq].first }
          .to include('f=has_model_ssim', 'GenericWork')
      end
    end

    context 'when limiting to collections' do
      let(:include_models) { :collections }

      it 'updates solr_parameters[:fq] to include only collections' do
        expect { builder.filter_models(solr_params) }
          .to change { solr_params[:fq].first }
          .to include('f=has_model_ssim', 'Collection')
      end
    end
  end
end
