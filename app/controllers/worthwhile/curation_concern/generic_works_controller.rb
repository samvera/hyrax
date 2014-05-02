module Worthwhile
  module CurationConcern
    class GenericWorksController < ApplicationController
      include Worthwhile::ThemedLayoutController
      load_and_authorize_resource class: "Worthwhile::GenericWork"
      with_themed_layout '1_column'

      respond_to :html

      def curation_concern
        @generic_work
      end
      helper_method :curation_concern

      
      def contributor_agreement
        @contributor_agreement ||= ContributorAgreement.new(curation_concern, current_user, params)
      end

      helper_method :contributor_agreement

      def new
      end

      def create
        return unless verify_acceptance_of_user_agreement!
        if actor.create
          after_create_response
        else
          setup_form
          respond_with([:curation_concern, curation_concern]) do |wants|
            wants.html { render 'new', status: :unprocessable_entity }
          end
        end
      end

      def show
      end

      def edit
      end

      def update
        if actor.update
          after_update_response
        else
          setup_form
          respond_with([:curation_concern, curation_concern]) do |wants|
            wants.html { render 'edit', status: :unprocessable_entity }
          end
        end
      end

      def destroy
        title = curation_concern.to_s
        curation_concern.destroy
        after_destroy_response(title)
      end

      protected

        def actor
          @actor ||= CurationConcern.actor(curation_concern, current_user, attributes_for_actor)
        end

        # Override setup_form in concrete controllers to get the form ready for display
        def setup_form
          if curation_concern.respond_to?(:contributor) && curation_concern.contributor.blank?
            curation_concern.contributor << current_user.name
          end
        end

        def verify_acceptance_of_user_agreement!
          return true if contributor_agreement.is_being_accepted?
          # Calling the new action to make sure we are doing our best to preserve
          # the input values; Its a stretch but hopefully it'll work
          self.new
          respond_with([:curation_concern, curation_concern]) do |wants|
            wants.html {
              flash.now[:error] = "You must accept the contributor agreement"
              render 'new', status: :conflict
            }
          end
          false
        end

        def _prefixes
          @_prefixes ||= super + ['worthwhile/curation_concern/base']
        end

        def after_create_response
          respond_with([:curation_concern, curation_concern])
        end

        def after_update_response
          if actor.visibility_changed?
            redirect_to confirm_curation_concern_permission_path(curation_concern)
          else
            respond_with([:curation_concern, curation_concern])
          end
        end

        def after_destroy_response(title)
          flash[:notice] = "Deleted #{title}"
          respond_with { |wants|
            wants.html { redirect_to main_app.catalog_index_path }
          }
        end

        def attributes_for_actor
          params[hash_key_for_curation_concern]
        end

        def hash_key_for_curation_concern
          'generic_work'
        end
    
    end
  end
end
