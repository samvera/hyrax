# frozen_string_literal: true
# This tests the Hyrax::WorksControllerBehavior module
RSpec.describe Hyrax::GenericWorksController, :active_fedora do
  routes { Rails.application.routes }

  let(:user) { create(:user) }

  before { sign_in user }

  context "JSON" do
    let(:admin_set) { create(:admin_set, id: 'admin_set_1', with_permission_template: { with_active_workflow: true }) }

    let(:resource) { create(:private_generic_work, user: user, admin_set_id: admin_set.id) }
    let(:resource_request) { get :show, params: { id: resource, format: :json } }

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

    describe 'created' do
      let(:actor) { double(create: create_status) }
      let(:create_status) { true }
      let(:model) { stub_model(GenericWork) }

      before do
        allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
        allow(controller).to receive(:curation_concern).and_return(model)
        post :create, params: { generic_work: { title: ['a title'] }, format: :json }
      end

      it "returns 201, renders show template sets location header" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of GenericWork
        expect(controller).to render_template('hyrax/base/show')
        expect(response.code).to eq "201"
        expect(response.location).to eq main_app.hyrax_generic_work_path(model, locale: 'en')
      end
    end

    # The clean is here because this test depends on the repo not having an AdminSet/PermissionTemplate created yet
    describe 'failed create', :clean_repo do
      before { post :create, params: { generic_work: {}, format: :json } }

      it 'returns 422 and the errors' do
        # NOTE: this passes in all four 2.7/valkyrie and 3.2/valkyrie pipelines, but does not pass locally in koppie
        # because Hyrax::WorksControllerBehavior#form_err_msg doesn't return the same type of message that
        # Hyrax::WorksControllerBehavior#create does
        resource = assigns[:curation_concern].respond_to?(:errors) ? assigns[:curation_concern] : assigns[:form]
        expect(response.code).to eq '422'
        expect(response).to respond_unprocessable_entity(errors: resource.errors.messages.as_json)
      end
    end

    describe 'found' do
      before { resource_request }
      it "returns json of the work" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(controller).to render_template('hyrax/base/show')
        expect(response.code).to eq "200"
      end
    end

    describe 'updated' do
      before { put :update, params: { id: resource, generic_work: { title: ['updated title'] }, format: :json } }
      it "returns 200, renders show template sets location header" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of GenericWork
        expect(controller).to render_template('hyrax/base/show')
        expect(response.code).to eq "200"
        created_resource = assigns[:curation_concern]
        expect(response.location).to eq main_app.hyrax_generic_work_path(created_resource, locale: 'en')
      end
    end

    describe 'failed update' do
      before { post :update, params: { id: resource, generic_work: { title: [''] }, format: :json } }
      it "returns 422 and the errors" do
        expect(response).to respond_unprocessable_entity(errors: { title: ["Your work must have a title."] })
      end
    end
  end
end
