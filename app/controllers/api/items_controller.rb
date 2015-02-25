module API
  # Adds an endpoint that consumes and RESTfully emits JSON from Arkivo
  # representing new and updated Zotero-managed publications. An item in the
  # Zotero parlance is mapped to a GenericFile in Sufia.
  class ItemsController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_filter :validate_item, only: [:create, :update]
    before_filter :authorize_token
    before_filter :my_load_and_authorize_resource, only: [:update, :destroy, :show]

    attr_reader :item

    def create
      head :created, location: sufia.api_item_path(actor.create_file_from_item)
    end

    def update
      actor.update_file_from_item(@file)
      head :no_content
    end

    def destroy
      actor.destroy_file(@file)
      head :no_content
    end

    def show
      head :no_content
    end

    private

      def my_load_and_authorize_resource
        @file = GenericFile.find(params[:id])

        unless user.can? :edit, @file
          return render plain: "#{user} lacks access to #{@file}", status: :unauthorized
        end

        if @file.arkivo_checksum.nil?
          return render plain: "Forbidden: #{@file} not deposited via Arkivo", status: :forbidden
        end
      rescue ActiveFedora::ObjectNotFoundError
        return render plain: "id '#{params[:id]}' not found", status: :not_found
      end

      def actor
        Sufia::Arkivo::Actor.new(user, item)
      end

      def token
        (request.get? || request.delete?) ? params[:token] : item['token']
      end

      def user
        User.find_by(arkivo_token: token)
      end

      def validate_item
        return render plain: 'no item parameter', status: :bad_request if params[:item].blank?
        Sufia::Arkivo::SchemaValidator.new(params[:item]).call
      rescue Sufia::Arkivo::InvalidItem => exception
        return render plain: "invalid item parameter: #{exception.message}", status: :bad_request
      else
        @item = JSON.parse(params[:item])
      end

      def authorize_token
        unless valid_token?
          return render plain: "invalid user token: #{token}", status: :unauthorized
        end
      end

      def valid_token?
        user.present?
      end
  end
end
