# frozen_string_literal: true
module Hyrax
  class Admin::CollectionTypeParticipantsController < ApplicationController
    before_action do
      authorize! :manage, :collection_types
    end

    class_attribute :form_class
    self.form_class = Hyrax::Forms::Admin::CollectionTypeParticipantForm

    def create
      @collection_type_participant = Hyrax::CollectionTypeParticipant.new(collection_type_participant_params)
      if @collection_type_participant.save
        redirect_to(
          edit_admin_collection_type_path(@collection_type_participant.hyrax_collection_type_id, anchor: 'participants'),
          notice: I18n.t('update_notice', scope: 'hyrax.admin.collection_types.form_participants')
        )
      else
        redirect_to(
          edit_admin_collection_type_path(@collection_type_participant.hyrax_collection_type_id, anchor: 'participants'),
          alert: @collection_type_participant.errors.full_messages.to_sentence
        )
      end
    end

    def destroy
      @collection_type_participant = Hyrax::CollectionTypeParticipant.find(params[:id])
      if @collection_type_participant.destroy
        redirect_to(
          edit_admin_collection_type_path(@collection_type_participant.hyrax_collection_type_id, anchor: 'participants'),
          notice: I18n.t('remove_success', scope: 'hyrax.admin.collection_types.form_participants')
        )
      else
        redirect_to(
          edit_admin_collection_type_path(@collection_type_participant.hyrax_collection_type_id, anchor: 'participants'),
          alert: @collection_type_participant.errors.full_messages.to_sentence
        )
      end
    end

    def collection_type_participant_params
      params.require(:collection_type_participant).permit(:access, :agent_id, :agent_type, :hyrax_collection_type_id)
    end
  end
end
