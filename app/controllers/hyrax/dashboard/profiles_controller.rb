# frozen_string_literal: true
module Hyrax
  module Dashboard
    ## Shows and edit the profile of the current_user
    class ProfilesController < Hyrax::UsersController
      with_themed_layout 'dashboard'
      before_action :find_user
      authorize_resource class: '::User', instance_name: :user

      def show
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.profile'), hyrax.dashboard_profile_path

        @presenter = Hyrax::UserProfilePresenter.new(@user, current_ability)
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
        if conditionally_update
          handle_successful_update
          redirect_to hyrax.dashboard_profile_path(@user.to_param), notice: "Your profile has been updated"
        else
          redirect_to hyrax.edit_dashboard_profile_path(@user.to_param), alert: @user.errors.full_messages
        end
      end

      private

      # Update user if they sent user params, otherwise return true.
      # This is important because this controller is also handling removing trophies.
      # (but we should move that to a different controller)
      def conditionally_update
        return true unless params[:user]
        @user.update(user_params)
      end

      def handle_successful_update
        # TODO: this should be moved to TrophiesController
        process_trophy_removal
        UserEditProfileEventJob.perform_later(@user)
      end

      # if the user wants to remove any trophies, do that here.
      def process_trophy_removal
        params.keys.select { |k, _v| k.starts_with? 'remove_trophy_' }.each do |smash_trophy|
          smash_trophy = smash_trophy.sub(/^remove_trophy_/, '')
          current_user.trophies.where(work_id: smash_trophy).destroy_all
        end
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
