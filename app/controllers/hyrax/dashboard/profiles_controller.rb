# frozen_string_literal: true

module Hyrax
  module Dashboard
    ## Shows and edit the profile of the current_user
    class ProfilesController < Hyrax::UsersController
      layout 'dashboard'
      before_action :find_user
      authorize_resource class: '::User', instance_name: :user

      def show
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.profile'), hyrax.dashboard_profile_path
      end

      # Display form for users to edit their profile information
      def edit
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.profile'), hyrax.dashboard_profile_path

        @trophies = Hyrax::TrophyPresenter.find_by_user(@user)
      end

      # Process changes from profile form
      def update
        conditionally_set_user_attributes

        if @user.save
          handle_successful_update
          redirect_to hyrax.dashboard_profile_path(@user.to_param), notice: "Your profile has been updated"
        else
          redirect_to hyrax.edit_dashboard_profile_path(@user.to_param), alert: @user.errors.full_messages
        end
      end

      private

        def conditionally_set_user_attributes
          return true unless params[:user]
          @user.attributes = user_params
          case params[:user][:update_directory]
          when '1', 'true', true
            @user.populate_attributes
          end
        end

        def handle_successful_update
          # TODO: this should be moved to TrophiesController
          params.keys.select { |k, _v| k.starts_with? 'remove_trophy_' }.each do |smash_trophy|
            smash_trophy = smash_trophy.sub(/^remove_trophy_/, '')
            current_user.trophies.where(work_id: smash_trophy).destroy_all
          end
          UserEditProfileEventJob.perform_later(@user)
        end

        def user_params
          params.require(:user).permit(:avatar, :facebook_handle, :twitter_handle,
                                       :googleplus_handle, :linkedin_handle, :remove_avatar, :orcid)
        end

        def find_user
          @user = ::User.from_url_component(params[:id])
          raise ActiveRecord::RecordNotFound unless @user
        end
    end
  end
end
