require 'spec_helper'

describe BatchEditsController, :type => :controller do
  before do
    sign_in FactoryGirl.find_or_create(:jill)
    allow_any_instance_of(User).to receive(:groups).and_return([])
    request.env["HTTP_REFERER"] = 'test.host/original_page'
  end

  routes { Internal::Application.routes }

  describe "edit" do
    before do
      @one = GenericFile.new(creator: ["Fred"], language: ['en'])
      @one.apply_depositor_metadata('mjg36')
      @two = GenericFile.new(creator: ["Wilma"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar'])
      @two.apply_depositor_metadata('mjg36')
      @one.save!
      @two.save!
      controller.batch = [@one.id, @two.id]
      expect(controller).to receive(:can?).with(:edit, @one.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, @two.id).and_return(true)
    end

    it "should be successful" do
      get :edit
      expect(response).to be_successful
      expect(assigns[:terms]).to eq [:creator, :contributor, :description, :tag, :rights, :publisher,
                        :date_created, :subject, :language, :identifier, :based_near, :related_url]
      expect(assigns[:generic_file].creator).to eq ["Fred", "Wilma"]
      expect(assigns[:generic_file].publisher).to eq ["Rand McNally"]
      expect(assigns[:generic_file].language).to eq ["en"]
    end

    it "should set the breadcrumb trail" do
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.files'), Sufia::Engine.routes.url_helpers.dashboard_files_path)
      get :edit
    end
  end

  describe "update" do
    let!(:one) do
      GenericFile.create(creator: ["Fred"], language: ['en']) do |file|
        file.apply_depositor_metadata('mjg36')
      end
    end

    let!(:two) do
      GenericFile.create(creator: ["Fred"], language: ['en']) do |file|
        file.apply_depositor_metadata('mjg36')
      end
    end

    before do
      controller.batch = [one.id, two.id]
      expect(controller).to receive(:can?).with(:edit, one.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, two.id).and_return(true)
    end

    let(:mycontroller) { "my/files" }

    it "should be successful" do
      put :update, update_type: "delete_all"
      expect(response).to redirect_to(Sufia::Engine.routes.url_for(controller: "dashboard", only_path: true))
      expect { GenericFile.find(one.id) }.to raise_error(Ldp::Gone)
      expect { GenericFile.find(two.id) }.to raise_error(Ldp::Gone)
    end

    it "should redirect to the return controller" do
      put :update, update_type: "delete_all", return_controller: mycontroller
      expect(response).to redirect_to(Sufia::Engine.routes.url_for(controller: mycontroller, only_path: true))
    end

    it "should update the records" do
      put :update, update_type: "update", generic_file: { subject: ["zzz"] }
      expect(response).to be_redirect
      expect(GenericFile.find(one.id).subject).to eq ["zzz"]
      expect(GenericFile.find(two.id).subject).to eq ["zzz"]
    end

    it "should update permissions" do
      put :update, update_type: "update", visibility: "authenticated"
      expect(response).to be_redirect
      expect(GenericFile.find(one.id).visibility).to eq "authenticated"
      expect(GenericFile.find(two.id).visibility).to eq "authenticated"
    end
  end

end
