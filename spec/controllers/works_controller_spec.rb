require 'spec_helper'

describe CurationConcerns::GenericWorksController, type: :controller do
  routes { Rails.application.routes }
  let(:user) { create(:user) }
  before { sign_in user }

  describe "#edit" do
    let(:work) {
      GenericWork.create(creator: ["Depeche Mode"], title: ["Strangelog"], language: ['en']) do |gw|
        gw.apply_depositor_metadata(user.email)
      end
    }

    it "allows edit on a work" do
      get :edit, id: work.id
      expect(response).to be_success
    end

    it "prevents edit on a work that still is being processed" do
      allow_any_instance_of(GenericWork).to receive(:processing?).and_return(true)
      expect { get :edit, id: work.id }.to raise_error(/Cannot edit a work that still is being processed/)
    end
  end

  describe "#create" do
    # TODO: this needs to be unskiped when #1699 is done.
    context "from browse everything", skip: true do
      let(:batch) { UploadSet.create }
      let(:upload_set_id) { batch.id }

      before do
        @json_from_browse_everything = { "0" => { "url" => "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt", "expires" => "2014-03-31T20:37:36.214Z", "file_name" => "filepicker-demo.txt.txt" }, "1" => { "url" => "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "expires" => "2014-03-31T20:37:36.731Z", "file_name" => "Getting+Started.pdf" } }
      end
      context "when no work_id is passed" do
        it "ingests files from provide URLs" do
          skip "Creating a FileSet without a parent work is not yet supported"
          expect(ImportUrlJob).to receive(:perform_later).twice
          expect { post :create, selected_files: @json_from_browse_everything,
                                 upload_set_id: upload_set_id,
                                 file_set: {}
          }.to change(FileSet, :count).by(2)
          created_files = FileSet.all
          ["https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt"].each do |url|
            expect(created_files.map(&:import_url)).to include(url)
          end
          ["filepicker-demo.txt.txt", "Getting+Started.pdf"].each do |filename|
            expect(created_files.map(&:label)).to include(filename)
          end
        end
      end

      context "when a work id is passed" do
        let(:work) do
          GenericWork.create!(title: ['test title']) do |w|
            w.apply_depositor_metadata(user)
          end
        end
        it "records the work" do
          expect(ImportUrlJob).to receive(:perform_later).twice
          expect {
            post :create, selected_files: @json_from_browse_everything,
                          parent_id: work.id,
                          file_set: {},
                          upload_set_id: upload_set_id
          }.to change(FileSet, :count).by(2)
          created_files = FileSet.all
          created_files.each { |f| expect(f.generic_works).to include work }
        end
      end

      context "when a work id is not passed" do
        it "creates the work" do
          skip "Creating a FileSet without a parent work is not yet supported"
          expect(ImportUrlJob).to receive(:new).twice
          expect {
            post :create, selected_files: @json_from_browse_everything,
                          file_set: {},
                          upload_set_id: upload_set_id
          }.to change(FileSet, :count).by(2)
          created_files = FileSet.all
          expect(created_files[0].generic_works.first).not_to eq created_files[1].generic_works.first
        end
      end
    end
  end
end
