require 'spec_helper'

describe CurationConcern::LinkedResourcesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:another_user) { FactoryGirl.create(:user) }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:parent) {
    FactoryGirl.create_curation_concern(:generic_work, user, {visibility: visibility})
  }

  let(:linked_resource) { FactoryGirl.create(:linked_resource, batch: parent, user: user) }

  let(:you_tube_link) { 'http://www.youtube.com/watch?v=oHg5SJYRHA0' }

  describe '#new' do
    it 'renders a form if you can edit the parent' do
      sign_in(user)
      parent
      get :new, parent_id: parent.to_param
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end

    it 'redirects if you cannot edit the parent' do
      sign_in(another_user)
      parent
      get :new, parent_id: parent.to_param
      expect(response.status).to eq 401
      expect(response).to render_template(:unauthorized)
    end
  end

  describe '#create' do
    let(:actor) { double('actor') }
    let(:actors_action) { :create }
    let(:success) { true }
    let(:failure) { false }

    it 'redirects to the parent work' do
      sign_in(user)
      parent
      expect(actor).to receive(actors_action).and_return(success)
      controller.actor = actor

      post(:create, parent_id: parent.to_param,
           linked_resource: { url: you_tube_link }
           )

      expect(response).to(
        redirect_to(controller.polymorphic_path([:curation_concern, parent]))
      )
    end

    describe 'failure' do
      it 'renders the form' do
        sign_in(user)
        parent
        expect(actor).to receive(actors_action).and_return(failure)
        controller.actor = actor

        post(:create, parent_id: parent.to_param,
             linked_resource: { url: you_tube_link }
             )
        expect(response).to render_template('new')
        expect(response.status).to eq 422
      end
    end
  end
    describe '#edit' do
      it 'should be successful' do
        linked_resource
        sign_in user
        get :edit, id: linked_resource.to_param
        expect(controller.curation_concern).to be_kind_of(Worthwhile::LinkedResource)
        expect(response).to be_successful
      end
    end

    describe '#update' do
      let(:updated_title) { Time.now.to_s }
      let(:failing_actor) {
        expect(actor).to receive(:update).and_return(false)
        actor
      }
      let(:successful_actor) {
        expect(actor).to receive(:update).and_return(true)
        actor
      }
      let(:actor) { double('actor') }
      it 'renders form when unsuccessful' do
        linked_resource
        controller.actor = failing_actor
        sign_in(user)
        put :update, id: linked_resource.to_param, linked_resource: {title: updated_title}
        expect(response).to render_template('edit')
        expect(response.status).to eq 422
      end

      it 'redirects to parent when successful' do
        linked_resource
        controller.actor = successful_actor
        sign_in(user)
        put :update, id: linked_resource.to_param, linked_resource: {title: updated_title}
        expect(response.status).to eq(302)
        expect(response).to(
          redirect_to(
            controller.polymorphic_path([:curation_concern, linked_resource.batch])
          )
        )
      end
  end

  describe '#destroy' do
    it 'should be successful if file exists' do
      parent = linked_resource.batch
      sign_in(user)
      delete :destroy, id: linked_resource.to_param
      expect(response.status).to eq(302)
      expect(response).to redirect_to(controller.polymorphic_path([:curation_concern, parent]))
    end
  end

end
