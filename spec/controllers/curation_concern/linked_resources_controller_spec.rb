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
      expect(response).to render_template(:new)
      response.should be_successful
    end

    context "when user doesn't have access to the parent" do
      before do
        sign_in(another_user)
        parent
      end
      it "shows the unauthorized page" do
        get :new, parent_id: parent.to_param
        expect(response.code).to eq '401'
      end
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
      actor.should_receive(actors_action).and_return(success)
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
        actor.should_receive(actors_action).and_return(failure)
        controller.actor = actor

        post(:create, parent_id: parent.to_param,
             linked_resource: { url: you_tube_link }
             )
        expect(response).to render_template('new')
        response.status.should == 422
      end
    end
  end
    describe '#edit' do
      it 'should be successful' do
        linked_resource
        sign_in user
        get :edit, id: linked_resource.to_param
        controller.curation_concern.should be_kind_of(Worthwhile::LinkedResource)
        response.should be_successful
      end
    end

    describe '#update' do
      let(:updated_title) { Time.now.to_s }
      let(:failing_actor) {
        actor.
        should_receive(:update).
        and_return(false)
        actor
      }
      let(:successful_actor) {
        actor.should_receive(:update).and_return(true)
        actor
      }
      let(:actor) { double('actor') }
      it 'renders form when unsuccessful' do
        linked_resource
        controller.actor = failing_actor
        sign_in(user)
        put :update, id: linked_resource.to_param, linked_resource: {title: updated_title}
        expect(response).to render_template('edit')
        response.status.should == 422
      end

      it 'redirects to parent when successful' do
        linked_resource
        controller.actor = successful_actor
        sign_in(user)
        put :update, id: linked_resource.to_param, linked_resource: {title: updated_title}
        expect(response.status).to eq(302)
        expect(response).to(
          redirect_to(
            controller.polymorphic_path([:curation_concern, linked_resource])
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
