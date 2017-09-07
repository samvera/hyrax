RSpec.describe Hyrax::Dashboard::NestCollectionsController do
  routes { Hyrax::Engine.routes }
  let(:child_id) { 'child1' }
  let(:parent_id) { 'parent1' }
  let(:child) { instance_double(Collection, title: "Awesome Child") }
  let(:parent) { instance_double(Collection, title: "Uncool Parent") }

  describe '#blacklight_config' do
    subject { controller.blacklight_config }

    it { is_expected.to be_a(Blacklight::Configuration) }
  end

  describe '#repository' do
    subject { controller.repository }

    it { is_expected.to be_a(Blacklight::Solr::Repository) }
  end

  describe 'GET #new_within' do
    subject { get 'new_within', params: { child_id: child_id } }

    before do
      allow(Collection).to receive(:find).with(child_id).and_return(child)
    end

    it "authorizes the child, assigns @form, and renders the template" do
      expect(controller).to receive(:authorize!).with(:edit, child).and_return(true)
      subject
      expect(assigns(:form).child).to eq(child)
      expect(assigns(:form).parent).to be_nil
      expect(subject).to render_template('new_within')
    end
  end

  describe 'POST #create_within' do
    subject { post 'create_within', params: { child_id: child_id, parent_id: parent_id } }

    before do
      allow(Collection).to receive(:find).with(child_id).and_return(child)
      allow(Collection).to receive(:find).with(parent_id).and_return(parent)
    end

    describe 'when save fails' do
      let(:form_class_with_failed_save) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def save
            false
          end
        end
      end

      before do
        controller.form_class = form_class_with_failed_save
      end

      it 'authorizes then renders the form again' do
        expect(controller).to receive(:authorize!).with(:edit, child).and_return(true)
        subject
        expect(response).to render_template('new_within')
      end
    end
    describe 'when save succeeds' do
      let(:form_class_with_successful_save) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def save
            true
          end
        end
      end

      before do
        controller.form_class = form_class_with_successful_save
      end

      it 'authorizes, flashes a notice, and redirects' do
        expect(controller).to receive(:authorize!).with(:edit, child).and_return(true)
        subject
        expect(response).to redirect_to(dashboard_collection_path(child))
        expect(flash[:notice]).to be_a(String)
      end
    end
  end
end
