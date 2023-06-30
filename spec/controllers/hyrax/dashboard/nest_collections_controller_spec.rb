# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::NestCollectionsController do
  routes { Hyrax::Engine.routes }
  let(:user) { FactoryBot.create(:user) }
  let(:parameters) { { child_id: child.id, parent_id: parent.id } }

  let(:child) do
    FactoryBot.valkyrie_create(:hyrax_collection, :public)
  end

  let(:parent) do
    FactoryBot.valkyrie_create(:hyrax_collection, :public, user: user)
  end

  before { sign_in(user) }

  its(:blacklight_config) { is_expected.to be_a(Blacklight::Configuration) }
  its('blacklight_config.repository') { is_expected.to be_a(Blacklight::Solr::Repository) }

  let(:form_class_base) do
    Class.new do
      attr_reader :child, :parent
      def initialize(parent: nil, parent_id: nil, child: nil, child_id: nil, context:)
        @parent = parent || (parent_id.present? && Hyrax.query_service.find_by(id: parent_id))
        @child = child || (child_id.present? && Hyrax.query_service.find_by(id: child_id))
        @context = context
      end
    end
  end

  let(:form_class_with_failed_save) do
    Class.new(form_class_base) do
      def save
        false
      end

      def errors
        ActiveModel::Errors.new([:always_fail])
      end
    end
  end

  let(:form_class_with_successful_save) do
    Class.new(form_class_base) do
      def save
        true
      end
    end
  end

  let(:form_class_with_failed_validation) do
    Class.new(form_class_base) do
      def validate_add
        false
      end

      def errors
        ActiveModel::Errors.new([:always_fail_validation])
      end
    end
  end

  let(:form_class_with_successful_validation) do
    Class.new(form_class_base) do
      def validate_add
        true
      end
    end
  end

  let(:form_class_remove_fails) do
    Class.new(form_class_base) do
      def remove
        false
      end

      def errors
        ActiveModel::Errors.new([:always_fail_remove])
      end
    end
  end

  let(:form_class_removed) do
    Class.new(form_class_base) do
      def remove
        true
      end

      def errors; end
    end
  end

  describe 'POST #create_relationship_within' do
    let(:parameters) do
      { child_id: child.id, parent_id: parent.id, source: 'my' }
    end

    describe 'when save fails' do
      before { controller.form_class = form_class_with_failed_save }

      it 'authorizes then renders the form again' do
        post 'create_relationship_within', params: parameters

        expect(response).to redirect_to(my_collections_path)
      end
    end

    context 'when save succeeds' do
      before { controller.form_class = form_class_with_successful_save }

      it 'authorizes, flashes a notice, and redirects' do
        post 'create_relationship_within', params: parameters

        expect(response).to redirect_to(my_collections_path)
        expect(flash[:notice]).to be_a(String)
      end
    end
  end

  describe 'GET #create_collection_under' do
    let(:parameters) do
      { child_id: child.id, parent_id: parent.id, source: 'show' }
    end

    describe 'when validation fails' do
      before { controller.form_class = form_class_with_failed_validation }

      it 'authorizes then renders the form again' do
        get 'create_collection_under', params: parameters

        expect(response).to redirect_to(dashboard_collection_path(parent.id))
      end
    end

    describe 'when validation succeeds' do
      before { controller.form_class = form_class_with_successful_validation }

      it 'authorizes, flashes a notice, and redirects' do
        get 'create_collection_under', params: parameters

        expect(response)
          .to redirect_to new_dashboard_collection_path(collection_type_id: Hyrax::CollectionType.for(collection: parent).id,
                                                        parent_id: parent.id)
      end
    end
  end

  describe 'POST #create_relationship_under' do
    let(:parameters) do
      { child_id: child.id, parent_id: parent.id, source: 'show' }
    end

    describe 'when save fails' do
      before { controller.form_class = form_class_with_failed_save }

      it 'authorizes then renders the form again' do
        post 'create_relationship_under', params: parameters

        expect(response).to redirect_to(dashboard_collection_path(parent))
      end
    end

    describe 'when save succeeds' do
      before { controller.form_class = form_class_with_successful_save }

      it 'authorizes, flashes a notice, and redirects' do
        post 'create_relationship_under', params: parameters

        expect(response).to redirect_to(dashboard_collection_path(parent))
        expect(flash[:notice]).to be_a(String)
      end
    end
  end

  describe 'POST #remove_relationship_above' do
    describe 'when remove fails' do
      before { controller.form_class = form_class_remove_fails }

      it 'authorizes then renders the form again' do
        post 'remove_relationship_above', params: parameters

        expect(response).to redirect_to(dashboard_collection_path(child))
      end
    end

    describe 'when remove succeeds' do
      before { controller.form_class = form_class_removed }

      it 'authorizes, flashes a notice, and redirects' do
        post 'remove_relationship_above', params: parameters

        expect(response).to redirect_to(dashboard_collection_path(child))
        expect(flash[:notice]).to be_a(String)
      end
    end
  end

  describe 'POST #remove_relationship_under' do
    describe 'when remove fails' do
      before { controller.form_class = form_class_remove_fails }

      it 'authorizes then renders the form again' do
        post 'remove_relationship_under', params: parameters

        expect(response).to redirect_to(dashboard_collection_path(parent))
      end
    end

    describe 'when remove succeeds' do
      before { controller.form_class = form_class_removed }

      it 'authorizes, flashes a notice, and redirects' do
        post 'remove_relationship_under', params: parameters

        expect(response).to redirect_to(dashboard_collection_path(parent))
        expect(flash[:notice]).to be_a(String)
      end
    end
  end
end
