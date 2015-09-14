require 'spec_helper'

describe CurationConcerns::GenericFilesController do
  let(:user) { create(:user) }
  let(:parent) { FactoryGirl.create(:generic_work, edit_users: [user.user_key], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
  let(:generic_file) do
    generic_file = create(:generic_file, user: user)
    parent.generic_files << generic_file
    generic_file
  end
  let(:file) { fixture_file_upload('/world.png', 'image/png') }
  let(:empty_file) { fixture_file_upload('/empty_file.txt', 'text/plain') }

  before { sign_in user }

  context "JSON" do
    let(:resource) { generic_file }
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
      it { is_expected.to respond_not_found(description: 'Object non-existent-pid not found in solr') }
    end
    describe 'created' do
      before do
        allow(CharacterizeJob).to receive(:perform_later)
        post :create, generic_file: { title: ['a title'], files: [file] }, parent_id: parent.id, format: :json
      end
      it "returns 201, renders jq_upload json template and sets location header" do
        expect(assigns[:generic_file]).to be_instance_of ::GenericFile # this object is used by the jbuilder template
        expect(controller).to render_template('curation_concerns/generic_files/jq_upload')
        expect(response.status).to eq 201
        created_resource = controller.curation_concern
        expect(response.location).to eq main_app.curation_concerns_generic_file_path(created_resource)
      end
    end
    describe 'failed create: no file' do
      before { post :create, generic_file: { title: ["foo"] }, parent_id: parent.id, format: :json }
      it { is_expected.to respond_bad_request(message: 'Error! No file to save') }
    end
    describe 'failed create: bad file' do
      before { post :create, generic_file: { files: ['not a file'] }, parent_id: parent.id, format: :json }
      it { is_expected.to respond_bad_request(message: 'Error! No file for upload', description: 'unknown file') }
    end
    describe 'failed create: empty file' do
      before { post :create, generic_file: { files: [empty_file] }, parent_id: parent.id, format: :json }
      it { is_expected.to respond_unprocessable_entity(errors: { files: "#{empty_file.original_filename} has no content! (Zero length file)" }, description: I18n.t('curation_concerns.api.unprocessable_entity.empty_file')) }
    end
    describe 'failed create: solr error' do
      before do
        allow(controller).to receive(:process_file).and_raise(RSolr::Error::Http.new(controller.request, response))
        post :create, generic_file: { files: [file] }, parent_id: parent.id, format: :json
      end
      it { is_expected.to respond_internal_error(message: 'Error occurred while creating generic file.') }
    end
    describe 'found' do
      before { resource_request }
      it "returns json of the work" do
        expect(assigns[:generic_file]).to be_instance_of ::GenericFile # this object is used by the jbuilder template
        expect(controller).to render_template('curation_concerns/generic_files/show')
        expect(response.code).to eq "200"
      end
    end
    describe 'updated' do
      before { put :update, id: resource, generic_file: { title: ['updated title'] }, format: :json }
      it "returns json of updated work and sets location header" do
        expect(assigns[:generic_file]).to be_instance_of ::GenericFile # this object is used by the jbuilder template
        expect(controller).to render_template('curation_concerns/generic_files/show')
        expect(response.status).to eq 200
        created_resource = assigns[:generic_file]
        expect(response.location).to eq main_app.curation_concerns_generic_file_path(created_resource)
      end
    end
    describe 'failed update' do
      before {
        expect(controller).to receive(:update_metadata) do
          controller.curation_concern.errors.add(:some_field, "This is not valid. Fix it.")
          false
        end
        post :update, id: resource, generic_file: { title: nil, depositor: nil }, format: :json
      }
      it "returns 422 and the errors" do
        expect(response).to respond_unprocessable_entity(errors: { "some_field": ["This is not valid. Fix it."] })
      end
    end
  end
end
