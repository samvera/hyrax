require 'spec_helper'

describe GenericWork do

  describe "Using services in Hydra::PCDM" do
    # Ideally we shouldn't need to call Hydra::PCDM
    # from Sufia. For now I am because some of the
    # functionality that I want to test has not been
    # implemented in Hydra::Works.
    collection = Hydra::PCDM::Collection.create
    object1 = Hydra::PCDM::Object.create
    object2 = Hydra::PCDM::Object.create
    Hydra::PCDM::AddObjectToCollection.call(collection, object1)
    Hydra::PCDM::AddObjectToCollection.call(collection, object2)
    objects = Hydra::PCDM::GetObjectsFromCollection.call(collection)
  end

  describe "Using services in Hydra::Works" do
    gf = Hydra::Works::GenericFile.create
    path = fixture_path + '/world.png'
    Hydra::Works::UploadFileToGenericFile.call(gf, path)
  end

  describe "Prototyping for GenericWorkActor.attach_file Ticket #103" do
    # See https://github.com/projecthydra-labs/hydra-works/issues/103
    #
    # Original
    # generic_file = GenericFile.new
    # actor = Sufia::GenericFile::Actor.new(generic_file, user)
    # actor.create_content(file, file.original_filename, file.content_type)
    # actor.create_metadata(curation_concern.id, curation_concern.id)
    # generic_file.generic_work = curation_concern
    # generic_file.visibility = visibility
    # stat = Worthwhile::CurationConcern.attach_file(generic_file, user, file)
    # curation_concern.generic_files += [generic_file]

    # Prototype
    #   Currently Sufia::GenericFile includes Hydra::Works::GenericFileBehavior
    #   which implies a Non-RDF Source (with only tech metadata and RDF type
    #   PCDMTerms.File)
    #
    #   Is this correct? Should Sufia::GenericFile map to a pcdm:File or to
    #   pcdm:Object?
    #
    #   If Sufia::GenericFile maps to pcdm:File we need a new class to hold the
    #   many derivatives of the file (binary, text, thumb) Sufia::MasterFile ?
    #
    #   If Sufia::GenericFile maps to pcdm:Object (via include
    #   Hydra::Works::GenericWork) that will allow for many pcdm:Files
    #   objects to be attached (one per derivative.) I think this is what we want.
    #   If we do this, then our GenericWork will also need to be mapped to
    #   pcdm:Object to perform its role as container for other pcdm:Objects.
    #
    #   See also https://docs.google.com/drawings/d/1-NkkRPpGpZGoTimEpYTaGM1uUPRaT0SamuWDITvtG_8/edit
    #
    # TODO:
    #   Update our GenericFile include Hydra::Works::GenericWork
    #   (as opossed to Hydra::Works::GenericFileBehavior)
    #
    #   Update our GenericWork (currently GenericWorkActor)
    #
    #   Is that right?
    #
    gw = Hydra::Works::GenericWork.create
    gf = Hydra::Works::GenericFile.create
    path = fixture_path + '/world.png'
    Hydra::Works::UploadFileToGenericFile.call(gf, path)
    # TODO: We still need this service: Hydra::Works::AddFileToWork.call(gw, gf)
  end

  describe ".properties" do
    subject { described_class.properties.keys }
    it { is_expected.to include("has_model", "create_date", "modified_date") }
  end

  describe "basic metadata" do
    it "should have dc properties" do
      subject.title = ['foo', 'bar']
      expect(subject.title).to eq ['foo', 'bar']
    end
  end

  describe "associations" do
    let(:file) { GenericFile.new.tap {|gf| gf.apply_depositor_metadata("user")} }
    context "base model" do
      subject { GenericWork.create(title: ['test'], generic_files: [file]) }

      it "should have many generic files" do
        expect(subject.generic_files).to eq [file]
      end
    end

    context "sub-class" do
      before do
        class TestWork < GenericWork
        end
      end

      subject { TestWork.create(title: ['test'], generic_files: [file]) }

      it "should have many generic files" do
        expect(subject.generic_files).to eq [file]
      end
    end
  end

  describe "created for someone (proxy)" do
    let(:work) { GenericWork.new.tap {|gw| gw.apply_depositor_metadata("user")} }
    let(:transfer_to) { FactoryGirl.find_or_create(:jill) }

    it "transfers the request" do
      work.on_behalf_of = transfer_to.user_key
      stub_job = double('change depositor job')
      allow(ContentDepositorChangeEventJob).to receive(:new).and_return(stub_job)
      expect(Sufia.queue).to receive(:push).with(stub_job).once.and_return(true)
      work.save!
    end
  end

  describe "delegations" do
    let(:work) { GenericWork.new.tap {|gw| gw.apply_depositor_metadata("user")} }
    let(:proxy_depositor) { FactoryGirl.find_or_create(:jill) }
    before do
      work.proxy_depositor = proxy_depositor.user_key
    end
    it "should include proxies" do
      expect(work).to respond_to(:relative_path)
      expect(work).to respond_to(:depositor)
      expect(work.proxy_depositor).to eq proxy_depositor.user_key
    end
  end

  describe "trophies" do
    before do
      u = FactoryGirl.find_or_create(:jill)
      @w = GenericWork.new.tap do |gw|
        gw.apply_depositor_metadata(u)
        gw.save!
      end
      @t = Trophy.create(user_id: u.id, generic_work_id: @w.id)
    end
    it "should have a trophy" do
      expect(Trophy.where(generic_work_id: @w.id).count).to eq 1
    end
    it "should remove all trophies when work is deleted" do
      @w.destroy
      expect(Trophy.where(generic_work_id: @w.id).count).to eq 0
    end
  end

  describe "#destroy", skip: "Is this behavior we need? Could other works be pointing at the file?" do
    let(:file1) { GenericFile.new.tap {|gf| gf.apply_depositor_metadata("user")} }
    let(:file2) { GenericFile.new.tap {|gf| gf.apply_depositor_metadata("user")} }
    let!(:work) { GenericWork.create(files: [file1, file2]) }

    it "should destroy the files" do
      expect { work.destroy }.to change{ GenericFile.count }.by(-2)
    end
  end

  describe "metadata" do
    it "should have descriptive metadata" do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
      expect(subject).to respond_to(:related_url)
      expect(subject).to respond_to(:based_near)
      expect(subject).to respond_to(:part_of)
      expect(subject).to respond_to(:contributor)
      expect(subject).to respond_to(:creator)
      expect(subject).to respond_to(:title)
      expect(subject).to respond_to(:description)
      expect(subject).to respond_to(:publisher)
      expect(subject).to respond_to(:date_created)
      expect(subject).to respond_to(:date_uploaded)
      expect(subject).to respond_to(:date_modified)
      expect(subject).to respond_to(:subject)
      expect(subject).to respond_to(:language)
      expect(subject).to respond_to(:rights)
      expect(subject).to respond_to(:resource_type)
      expect(subject).to respond_to(:identifier)
    end
  end

  describe "#indexer" do
    subject { described_class.indexer }
    it { is_expected.to eq Sufia::GenericWorkIndexingService }
  end
end

