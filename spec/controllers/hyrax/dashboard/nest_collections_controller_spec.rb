# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::NestCollectionsController do
  routes { Hyrax::Engine.routes }
  let(:child_id) { 'child1' }
  let(:child) { instance_double(Collection, title: ["Awesome Child"]) }
  let(:parent) { create(:collection_lw, id: 'parent1', collection_type_settings: :nestable, title: ["Uncool Parent"]) }

  describe '#blacklight_config' do
    subject { controller.blacklight_config }

    it { is_expected.to be_a(Blacklight::Configuration) }
  end

  describe '#repository' do
    subject { controller.repository }

    it { is_expected.to be_a(Blacklight::Solr::Repository) }
  end

  describe 'POST #create_relationship_within' do
    subject { post 'create_relationship_within', params: { child_id: child_id, parent_id: parent.id, source: 'my' } }

    before do
      allow(Collection).to receive(:find).with(child_id).and_return(child)
      allow(Collection).to receive(:find).with(parent.id).and_return(parent)
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

          def errors; end
        end
      end

      before do
        controller.form_class = form_class_with_failed_save
        allow(controller).to receive(:authorize!).with(:read, child).and_return(true)
        allow(controller.form_class).to receive(:errors)
        allow(controller.form_class.errors).to receive(:full_messages).and_return(['huge mistake'])
      end

      it 'authorizes then renders the form again' do
        subject
        expect(response).to redirect_to(my_collections_path)
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
        allow(controller).to receive(:authorize!).with(:read, child).and_return(true)
      end

      it 'authorizes, flashes a notice, and redirects' do
        subject
        expect(response).to redirect_to(my_collections_path)
        expect(flash[:notice]).to be_a(String)
      end
    end
  end

  describe 'GET #create_collection_under' do
    subject { get 'create_collection_under', params: { child_id: nil, parent_id: parent.id, source: 'show' } }

    before do
      allow(Collection).to receive(:find).with(parent.id).and_return(parent)
    end

    describe 'when validation fails' do
      let(:form_class_with_failed_validation) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def validate_add
            false
          end

          def errors; end
        end
      end

      before do
        controller.form_class = form_class_with_failed_validation
        allow(controller).to receive(:authorize!).with(:deposit, parent).and_return(true)
        allow(controller.form_class).to receive(:errors)
        allow(controller.form_class.errors).to receive(:full_messages).and_return(['huge mistake'])
      end

      it 'authorizes then renders the form again' do
        subject
        expect(response).to redirect_to(dashboard_collection_path(parent.id))
      end
    end

    describe 'when validation succeeds' do
      let(:form_class_with_successful_validation) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def validate_add
            true
          end
        end
      end

      before do
        controller.form_class = form_class_with_successful_validation
        allow(controller).to receive(:authorize!).with(:deposit, parent).and_return(true)
      end

      it 'authorizes, flashes a notice, and redirects' do
        subject
        expect(response).to redirect_to new_dashboard_collection_path(collection_type_id: parent.collection_type.id, parent_id: parent.id)
      end
    end
  end

  describe 'POST #create_relationship_under' do
    subject { post 'create_relationship_under', params: { child_id: child_id, parent_id: parent.id, source: 'show' } }

    before do
      allow(Collection).to receive(:find).with(child_id).and_return(child)
      allow(Collection).to receive(:find).with(parent.id).and_return(parent)
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

          def errors; end
        end
      end

      before do
        controller.form_class = form_class_with_failed_save
        allow(controller).to receive(:authorize!).with(:deposit, parent).and_return(true)
        allow(controller.form_class).to receive(:errors)
        allow(controller.form_class.errors).to receive(:full_messages).and_return(['huge mistake'])
      end

      it 'authorizes then renders the form again' do
        subject
        expect(response).to redirect_to(dashboard_collection_path(parent))
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
        allow(controller).to receive(:authorize!).with(:deposit, parent).and_return(true)
      end

      it 'authorizes, flashes a notice, and redirects' do
        subject
        expect(response).to redirect_to(dashboard_collection_path(parent))
        expect(flash[:notice]).to be_a(String)
      end
    end
  end

  describe 'POST #remove_relationship_above' do
    subject { post 'remove_relationship_above', params: { child_id: child_id, parent_id: parent.id } }

    before do
      allow(Collection).to receive(:find).with(child_id).and_return(child)
      allow(Collection).to receive(:find).with(parent.id).and_return(parent)
    end

    describe 'when remove fails' do
      let(:form_class_remove_fails) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def remove
            false
          end

          def errors; end
        end
      end

      before do
        controller.form_class = form_class_remove_fails
        allow(controller).to receive(:authorize!).with(:edit, parent).and_return(false)
        allow(controller.form_class).to receive(:errors)
        allow(controller.form_class.errors).to receive(:full_messages).and_return(['unauthorized'])
      end

      it 'authorizes then renders the form again' do
        subject
        expect(response).to redirect_to(dashboard_collection_path(child))
      end
    end

    describe 'when remove succeeds' do
      let(:form_class_removed) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def remove
            true
          end

          def errors; end
        end
      end

      before do
        controller.form_class = form_class_removed
        allow(controller).to receive(:authorize!).with(:edit, parent).and_return(true)
      end

      it 'authorizes, flashes a notice, and redirects' do
        subject
        expect(response).to redirect_to(dashboard_collection_path(child))
        expect(flash[:notice]).to be_a(String)
      end
    end
  end

  describe 'POST #remove_relationship_under' do
    subject { post 'remove_relationship_under', params: { child_id: child_id, parent_id: parent.id } }

    before do
      allow(Collection).to receive(:find).with(child_id).and_return(child)
      allow(Collection).to receive(:find).with(parent.id).and_return(parent)
    end

    describe 'when remove fails' do
      let(:form_class_remove_fails) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def remove
            false
          end

          def errors; end
        end
      end

      before do
        controller.form_class = form_class_remove_fails
        allow(controller).to receive(:authorize!).with(:edit, parent).and_return(false)
        allow(controller.form_class).to receive(:errors)
        allow(controller.form_class.errors).to receive(:full_messages).and_return(['unauthorized'])
      end

      it 'authorizes then renders the form again' do
        subject
        expect(response).to redirect_to(dashboard_collection_path(parent))
      end
    end

    describe 'when remove succeeds' do
      let(:form_class_removed) do
        Class.new do
          attr_reader :child, :parent
          def initialize(parent:, child:, context:)
            @parent = parent
            @child = child
            @context = context
          end

          def remove
            true
          end

          def errors; end
        end
      end

      before do
        controller.form_class = form_class_removed
        allow(controller).to receive(:authorize!).with(:edit, parent).and_return(true)
      end

      it 'authorizes, flashes a notice, and redirects' do
        subject
        expect(response).to redirect_to(dashboard_collection_path(parent))
        expect(flash[:notice]).to be_a(String)
      end
    end
  end
end
