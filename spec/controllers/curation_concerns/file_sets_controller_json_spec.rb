require 'spec_helper'

describe CurationConcerns::FileSetsController do
  let(:user) { create(:user) }
  let(:parent) { create(:generic_work, edit_users: [user.user_key], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
  let(:file_set) do
    create(:file_set, user: user).tap do |file_set|
      parent.members << file_set
    end
  end
  let(:file) { fixture_file_upload('/world.png', 'image/png') }
  let(:empty_file) { fixture_file_upload('/empty_file.txt', 'text/plain') }

  before { sign_in user }

  context "JSON" do
    let(:resource) { file_set }
    let(:resource_request) { get :show, id: resource, format: :json }
    subject { response }
    describe "unauthorized" do
      before do
        sign_out user
        resource_request
      end
      it { is_expected.to respond_unauthorized }
    end

    describe "forbidden" do
      before do
        sign_in create(:user)
        resource_request
      end
      it { is_expected.to respond_forbidden }
    end

    describe 'not found' do
      before { get :show, id: "non-existent-pid", format: :json }
      it { is_expected.to respond_not_found(description: 'Could not find a resource that matches your request.') }
    end

    describe 'created' do
      it "returns 201, renders jq_upload json template and sets location header" do
        expect(controller.send(:actor)).to receive(:create_metadata).with(nil, parent, hash_including(:files, title: ['a title']))
        expect(controller.send(:actor)).to receive(:create_content).with(file).and_return(true)

        allow_any_instance_of(FileSet).to receive(:persisted?).and_return(true)
        allow_any_instance_of(FileSet).to receive(:to_param).and_return('999')

        post :create, file_set: { title: ['a title'], files: [file] }, parent_id: parent.id, format: :json

        expect(assigns[:file_set]).to be_instance_of ::FileSet # this object is used by the jbuilder template
        expect(controller).to render_template('curation_concerns/file_sets/jq_upload')
        expect(response.status).to eq 201
        created_resource = controller.curation_concern
        expect(response.location).to eq main_app.curation_concerns_file_set_path(created_resource)
      end
    end

    describe 'failed create: no file' do
      before { post :create, file_set: { title: ["foo"] }, parent_id: parent.id, format: :json }
      it { is_expected.to respond_bad_request(message: 'Error! No file to save') }
    end

    describe 'failed create: bad file' do
      before { post :create, file_set: { files: ['not a file'] }, parent_id: parent.id, format: :json }
      it { is_expected.to respond_bad_request(message: 'Error! No file for upload', description: 'unknown file') }
    end

    describe 'failed create: empty file' do
      before { post :create, file_set: { files: [empty_file] }, parent_id: parent.id, format: :json }
      it { is_expected.to respond_unprocessable_entity(errors: { files: "#{empty_file.original_filename} has no content! (Zero length file)" }, description: I18n.t('curation_concerns.api.unprocessable_entity.empty_file')) }
    end

    describe 'failed create: solr error' do
      before do
        allow(controller).to receive(:process_file).and_raise(RSolr::Error::Http.new(controller.request, response))
        post :create, file_set: { files: [file] }, parent_id: parent.id, format: :json
      end

      it { is_expected.to respond_internal_error(message: 'Error occurred while creating a FileSet.') }
    end

    describe 'found' do
      before { resource_request }
      it "returns json of the work" do
        expect(assigns[:file_set]).to be_instance_of ::FileSet # this object is used by the jbuilder template
        expect(controller).to render_template('curation_concerns/file_sets/show')
        expect(response.code).to eq "200"
      end
    end

    describe 'updated' do
      before { put :update, id: resource, file_set: { title: ['updated title'] }, format: :json }
      it "returns json of updated work and sets location header" do
        expect(assigns[:file_set]).to be_instance_of ::FileSet # this object is used by the jbuilder template
        expect(controller).to render_template('curation_concerns/file_sets/show')
        expect(response.status).to eq 200
        created_resource = assigns[:file_set]
        expect(response.location).to eq main_app.curation_concerns_file_set_path(created_resource)
      end
    end

    describe 'failed update' do
      before {
        expect(controller).to receive(:update_metadata) do
          controller.curation_concern.errors.add(:some_field, "This is not valid. Fix it.")
          false
        end
        post :update, id: resource, file_set: { title: nil, depositor: nil }, format: :json
      }
      it "returns 422 and the errors" do
        expect(response).to respond_unprocessable_entity(errors: { "some_field": ["This is not valid. Fix it."] })
      end
    end
  end
end
