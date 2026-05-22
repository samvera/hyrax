# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::AttributesHelper, type: :helper do
  describe '#conform_field' do
    it 'returns the field name when no render_term is set' do
      expect(helper.conform_field(:title, {})).to eq(:title)
    end

    it 'returns the render_term when set' do
      expect(helper.conform_field(:based_near, 'render_term' => :based_near_label)).to eq(:based_near_label)
    end

    it 'handles nil options' do
      expect(helper.conform_field(:title, nil)).to eq(:title)
    end
  end

  describe '#conform_options' do
    around do |example|
      original = I18n.locale
      example.run
      I18n.locale = original
    end

    it 'resolves :display_label to a :label using the current locale' do
      view_options = { display_label: { 'en' => 'Title', 'es' => 'Título' } }.with_indifferent_access
      I18n.locale = :es
      result = helper.conform_options(:title, view_options)
      expect(result[:label]).to eq('Título')
    end

    it 'falls back to :default when the current locale is missing' do
      view_options = { display_label: { 'default' => 'Title' } }.with_indifferent_access
      I18n.locale = :fr
      result = helper.conform_options(:title, view_options)
      expect(result[:label]).to eq('Title')
    end

    it 'derives a label from the field name when display_label is empty' do
      result = helper.conform_options(:date_created, {}.with_indifferent_access)
      expect(result[:label]).to eq('Date created')
    end
  end

  describe '#schema' do
    it 'returns nil for a nil model' do
      expect(helper.schema(nil)).to be_nil
    end

    it 'returns nil for a model without a schema method' do
      expect(helper.schema(Object.new)).to be_nil
    end

    it 'returns the schema when the model responds to :schema' do
      model = double('Model', schema: :a_schema)
      expect(helper.schema(model)).to eq(:a_schema)
    end
  end

  describe '#field_visible?' do
    let(:admin_user) { instance_double(User, admin?: true) }
    let(:non_admin_user) { instance_double(User, admin?: false) }
    let(:editor_presenter) { double('Presenter', editor?: true) }
    let(:non_editor_presenter) { double('Presenter', editor?: false) }

    context 'when no visibility flags are set' do
      it 'is true regardless of user' do
        allow(helper).to receive(:current_user).and_return(nil)
        expect(helper.field_visible?({}, non_editor_presenter)).to be true
      end
    end

    context 'when show_page is false' do
      let(:view_options) { { show_page: false } }

      it 'is false for admins' do
        allow(helper).to receive(:current_user).and_return(admin_user)
        expect(helper.field_visible?(view_options, editor_presenter)).to be false
      end

      it 'is false for non-admins' do
        allow(helper).to receive(:current_user).and_return(non_admin_user)
        expect(helper.field_visible?(view_options, non_editor_presenter)).to be false
      end

      it 'is false when there is no current_user' do
        allow(helper).to receive(:current_user).and_return(nil)
        expect(helper.field_visible?(view_options, non_editor_presenter)).to be false
      end
    end

    context 'when show_page is true' do
      it 'is true (does not suppress the field)' do
        allow(helper).to receive(:current_user).and_return(non_admin_user)
        expect(helper.field_visible?({ show_page: true }, non_editor_presenter)).to be true
      end
    end

    context 'when admin_only is set' do
      let(:view_options) { { admin_only: true } }

      it 'is true for admins' do
        allow(helper).to receive(:current_user).and_return(admin_user)
        expect(helper.field_visible?(view_options, non_editor_presenter)).to be true
      end

      it 'is false for non-admins' do
        allow(helper).to receive(:current_user).and_return(non_admin_user)
        expect(helper.field_visible?(view_options, non_editor_presenter)).to be false
      end

      it 'is false when there is no current_user' do
        allow(helper).to receive(:current_user).and_return(nil)
        expect(helper.field_visible?(view_options, non_editor_presenter)).to be false
      end
    end

    context 'when editor_only is set' do
      let(:view_options) { { editor_only: true } }

      before { allow(helper).to receive(:current_user).and_return(non_admin_user) }

      it 'is true when the presenter reports the user as an editor' do
        expect(helper.field_visible?(view_options, editor_presenter)).to be true
      end

      it 'is false when the presenter reports the user is not an editor' do
        expect(helper.field_visible?(view_options, non_editor_presenter)).to be false
      end

      it 'is false when the presenter does not respond to editor?' do
        expect(helper.field_visible?(view_options, Object.new)).to be false
      end
    end

    context 'when both admin_only and editor_only are set' do
      let(:view_options) { { admin_only: true, editor_only: true } }

      it 'requires both: passes only when user is admin and presenter reports editor' do
        allow(helper).to receive(:current_user).and_return(admin_user)
        expect(helper.field_visible?(view_options, editor_presenter)).to be true
      end

      it 'is false when user is admin but not an editor of the record' do
        allow(helper).to receive(:current_user).and_return(admin_user)
        expect(helper.field_visible?(view_options, non_editor_presenter)).to be false
      end

      it 'is false when user is an editor of the record but not an admin' do
        allow(helper).to receive(:current_user).and_return(non_admin_user)
        expect(helper.field_visible?(view_options, editor_presenter)).to be false
      end
    end
  end
end
