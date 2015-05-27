require 'spec_helper'

describe CurationConcerns::GenericWorksController do
  let(:public_work_factory_name) { :public_generic_work }
  let(:private_work_factory_name) { :work }

  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  describe "#show" do
    context "my own private work" do
      let(:a_work) { FactoryGirl.create(private_work_factory_name, user: user) }
      it "should show me the page" do
        get :show, id: a_work
        expect(response).to be_success
      end
    end

    context "someone elses private work" do
      let(:a_work) { FactoryGirl.create(private_work_factory_name) }
      it "should redirect and show unauthorized message" do
        get :show, id: a_work
        expect(response).to fail_redirect_and_flash(main_app.root_path, 'You are not authorized to access this page.')
      end
    end

    context "someone elses public work" do
      let(:a_work) { FactoryGirl.create(public_work_factory_name) }
      it "should show me the page" do
        get :show, id: a_work
        expect(response).to be_success
      end
    end

    context "when I am a repository manager" do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:a_work) { FactoryGirl.create(private_work_factory_name) }
      it "someone elses private work should show me the page" do
        get :show, id: a_work
        expect(response).to be_success
      end
    end
  end

  describe "#new" do
    context "my work" do
      it "should show me the page" do
        get :new
        expect(response).to be_success
      end
    end
  end

  describe "#create" do
    it "should create a work" do
      expect {
        post :create, generic_work: { title: ["a title"] }
      }.to change { GenericWork.count }.by(1)
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(assigns[:curation_concern])
    end
  end

  describe "#edit" do
    context "my own private work" do
      let(:a_work) { FactoryGirl.create(private_work_factory_name, user: user) }
      it "should show me the page" do
        get :edit, id: a_work
        expect(response).to be_success
      end
    end

    context "someone elses private work" do
      routes { Rails.application.class.routes }
      let(:a_work) { FactoryGirl.create(private_work_factory_name) }
      it "should redirect and show unauthorized message" do
        get :edit, id: a_work
        expect(response).to fail_redirect_and_flash(main_app.curation_concerns_generic_work_path(assigns[:curation_concern]), 'You are not authorized to access this page.')
      end
    end

    context "someone elses public work" do
      let(:a_work) { FactoryGirl.create(public_work_factory_name) }
      it "should show me the page" do
        get :edit, id: a_work
        expect(response).to fail_redirect_and_flash(main_app.curation_concerns_generic_work_path(assigns[:curation_concern]), 'You are not authorized to access this page.')
      end
    end

    context "when I am a repository manager" do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:a_work) { FactoryGirl.create(private_work_factory_name) }
      it "someone elses private work should show me the page" do
        get :edit, id: a_work
        expect(response).to be_success
      end
    end
  end

  describe "#update" do
    let(:a_work) { FactoryGirl.create(private_work_factory_name, user: user) }

    it "should update the work " do
      patch :update, id: a_work, generic_work: {  }
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(a_work)
    end

    describe "changing rights" do
      it "should prompt to change the files access" do
        allow(controller).to receive(:actor).and_return(double(update: true, visibility_changed?: true))
        patch :update, id: a_work
        expect(response).to redirect_to main_app.confirm_curation_concerns_permission_path(controller.curation_concern)
      end
    end

    describe "failure" do
      it "renders the form" do
        allow(controller).to receive(:actor).and_return(double(update: false, visibility_changed?: false))
        patch :update, id: a_work
        expect(response).to render_template('edit')
      end
    end

    context "someone elses public work" do
      let(:a_work) { FactoryGirl.create(public_work_factory_name) }
      it "should redirect and show unauthorized message" do
        get :update, id: a_work
        expect(response).to fail_redirect_and_flash(main_app.root_path, 'You are not authorized to access this page.')
      end
    end

    context "when I am a repository manager" do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      let(:a_work) { FactoryGirl.create(private_work_factory_name) }
      it "someone elses private work should update the work" do
        patch :update, id: a_work, generic_work: {  }
        expect(response).to redirect_to main_app.curation_concerns_generic_work_path(a_work)
      end
    end
  end

  describe "#destroy" do
    let(:work_to_be_deleted) { FactoryGirl.create(private_work_factory_name, user: user) }

    it "should delete the work" do
      delete :destroy, id: work_to_be_deleted
      expect(response).to redirect_to main_app.catalog_index_path()
      expect { GenericWork.find(work_to_be_deleted.id) }.to raise_error
    end

    context "someone elses public work" do
      let(:work_to_be_deleted) { FactoryGirl.create(private_work_factory_name) }
      it "should redirect and show unauthorized message" do
        delete :destroy, id: work_to_be_deleted
        expect(response).to fail_redirect_and_flash(main_app.root_path, 'You are not authorized to access this page.')
      end
    end

    context "when I am a repository manager" do
      let(:work_to_be_deleted) { FactoryGirl.create(private_work_factory_name) }
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it "someone elses private work should delete the work" do
        delete :destroy, id: work_to_be_deleted
        expect { GenericWork.find(work_to_be_deleted.id) }.to raise_error
      end
    end
  end
end
