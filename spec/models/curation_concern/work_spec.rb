require 'spec_helper'

describe CurationConcern::Work do
  context 'index_collection_pids' do
    let(:work){FactoryGirl.create(:essential_work) }
    let(:reloaded_work) { GenericWork.find(work.pid) }

    let(:collection){ FactoryGirl.create(:collection) }
    let(:reloaded_collection) { Collection.find(collection.pid) }

    let(:user) { FactoryGirl.create(:user) }

    it "should mix together all the goodness" do
      [::CurationConcern::WithGenericFiles, ::CurationConcern::HumanReadableType, Hydra::AccessControls::Permissions, ::CurationConcern::Embargoable, ::CurationConcern::WithEditors, Sufia::Noid, Sufia::ModelMethods, Hydra::Collections::Collectible, Solrizer::Common].each do |mixin|
        expect(work.class.ancestors).to include(mixin)
      end
    end
    
  end
end
