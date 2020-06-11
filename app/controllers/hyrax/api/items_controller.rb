# frozen_string_literal: true
module Hyrax
  module API
    # Adds an endpoint that consumes and RESTfully emits JSON from Arkivo
    # representing new and updated Zotero-managed publications. An item in the
    # Zotero parlance is mapped to a work in Hyrax.
    class ItemsController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :validate_item, only: [:create, :update]
      before_action :authorize_token
      before_action :my_load_and_authorize_resource, only: [:update, :destroy, :show]

      attr_reader :item

      def create
        head :created, location: hyrax.api_item_path(actor.create_work_from_item)
      end

      def update
        actor.update_work_from_item(@work)
        head :no_content
      end

      def destroy
        actor.destroy_work(@work)
        head :no_content
      end

      def show
        head :no_content
      end

      private

      def my_load_and_authorize_resource
        @work = Hyrax::WorkRelation.new.find(params[:id])

        return render plain: "#{user} lacks access to #{@work}", status: :unauthorized unless user.can? :edit, @work

        return render plain: "Forbidden: #{@work} not deposited via Arkivo", status: :forbidden if @work.arkivo_checksum.nil?
      rescue ActiveFedora::ObjectNotFoundError
        render plain: "id '#{params[:id]}' not found", status: :not_found
      end

      def actor
        Hyrax::Arkivo::Actor.new(user, item)
      end

      def token
        request.get? || request.delete? ? params[:token] : item['token']
      end

      def user
        ::User.find_by(arkivo_token: token)
      end

      def validate_item
        return render plain: 'no item parameter', status: :bad_request if post_data.blank?
        Hyrax::Arkivo::SchemaValidator.new(post_data).call
      rescue Hyrax::Arkivo::InvalidItem => exception
        render plain: "invalid item parameter: #{exception.message}", status: :bad_request
      else
        @item = JSON.parse(post_data)
      end

      def post_data
        request.raw_post
      end

      def authorize_token
        render plain: "invalid user token: #{token}", status: :unauthorized unless valid_token?
      end

      def valid_token?
        user.present?
      end
    end
  end
end
