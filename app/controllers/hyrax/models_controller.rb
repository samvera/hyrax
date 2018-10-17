module Hyrax
  class ModelsController < ApplicationController
    attr_accessor :properties, :class_name, :file_name

    # GET models
    def index
      json_response = { models: Hyrax.config.registered_curation_concern_types }
      respond_to do |wants|
        wants.html { render json: json_response }
        wants.json { render json: json_response }
        # additional_response_formats(wants)
      end
    end

    # GET model properties
    # @todo add required ?
    # @todo namespaced models
    def show
      @file_name = params[:id]
      @file_name.gsub!('__', '/') if file_name.include?('__')
      @class_name = params[:id].classify
      @properties = class_name.constantize.properties
      json_response = build_json_response
      respond_to do |wants|
        wants.html { render json: json_response }
        wants.json { render json: json_response }
        # additional_response_formats(wants)
      end
    rescue
      # @todo proper error
      render html: 'oh noes'
    end

    # POST
    def create
      # params[:validate] true|false
      # params[:no-op] true|false
      # validate anyway
      # create
    end

    private

      def build_json_response
        puts properties
        {
          file_name => {
            "class_name" => class_name,
            "properties" => build_property_map
          }
        }
      end

      def build_property_map
        props = []
        properties.keys.each do |prop|
          props << {
            prop => {
              # 'predicate' => properties[prop]['predicate'].to_s,
              'multiple' => properties[prop]['multiple'],
              'type' => properties[prop]['type'],
              # 'behaviors' => properties[prop]['behaviors'],
            }
          }
        end
        props
      end
  end
end
