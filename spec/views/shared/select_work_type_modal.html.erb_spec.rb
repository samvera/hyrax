# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'shared/_select_work_type_modal.html.erb', type: :view do
  include(Devise::Test::ControllerHelpers)
  let(:presenter) { instance_double Hyrax::SelectTypeListPresenter }
  let(:row1) { Hyrax::SelectTypePresenter.new(GenericWork) }
  let(:row2) { Hyrax::SelectTypePresenter.new(Hyrax.config.disable_wings ? Monograph : NamespacedWorks::NestedWork) }

  let(:expected_selector_collection_id_present) do
    'input[type="radio"][data-single="/concern/generic_works/new?add_works_to_collection=1"][data-batch="/batch_uploads/new?add_works_to_collection=1&payload_concern=GenericWork"]'
  end
  let(:dassie_expected_selector) do
    'input[type="radio"][data-single="/concern/namespaced_works/nested_works/new?add_works_to_collection=1"]' \
    '[data-batch="/batch_uploads/new?add_works_to_collection=1&payload_concern=NamespacedWorks%3A%3ANestedWork"]'
  end
  let(:koppie_expected_selector) do
    'input[type="radio"][data-single="/concern/monographs/new?add_works_to_collection=1"][data-batch="/batch_uploads/new?add_works_to_collection=1&payload_concern=Monograph"]'
  end

  before do
    allow(presenter).to receive(:each).and_yield(row1).and_yield(row2)
    # Because there is no i18n set up for this work type
    allow(row2).to receive(:name).and_return('Nested Work')
  end

  shared_context('with a rendered modal') { before { render 'shared/select_work_type_modal', create_work_presenter: presenter } }

  shared_examples('tests for expected selectors when collection id present') do
    it 'draws the modal with collection id' do
      expect(rendered).to(have_selector(expected_selector_collection_id_present))
      expect(rendered).to(have_selector(dassie_expected_selector)) unless Hyrax.config.disable_wings
      expect(rendered).to(have_selector(koppie_expected_selector)) if Hyrax.config.disable_wings
    end
  end

  context 'when no collections id' do
    include_context 'with a rendered modal'

    it 'draws the modal' do
      expect(rendered).to have_selector '#worktypes-to-create.modal'
      expect(rendered).to have_content 'Generic Work'
      expect(rendered).to have_content 'Nested Work'
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/generic_works/new"][data-batch="/batch_uploads/new?payload_concern=GenericWork"]'
      unless Hyrax.config.disable_wings
        expect(rendered).to(have_selector(
          'input[type="radio"][data-single="/concern/namespaced_works/nested_works/new"][data-batch="/batch_uploads/new?payload_concern=NamespacedWorks%3A%3ANestedWork"]'
        ))
      end
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/monographs/new"][data-batch="/batch_uploads/new?payload_concern=Monograph"]' if Hyrax.config.disable_wings
    end
  end

  context 'when collection id exists' do
    before { allow(view).to receive(:params).and_return(id: '1', controller: 'hyrax/dashboard/collections') }
    include_context 'with a rendered modal'

    include_examples 'tests for expected selectors when collection id present'
  end

  context 'when add_works_to_collection exists' do
    before { allow(view).to receive(:params).and_return(add_works_to_collection: '1') }
    include_context 'with a rendered modal'

    include_examples 'tests for expected selectors when collection id present'
  end
end
