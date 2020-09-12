module Api
  module V1
    class ApiController < ApplicationController
      before_action :authenticate_application!
      before_action :authenticate_api_user!
      before_action :initialize_updates_used_tracker

      after_action  :log_api_request

      def authenticate_application!
        @application_integration = ApplicationIntegration.find_by(application_token: params[:application_token])

        unless @application_integration
          # todo log error
          render json: {
            "Error" => "Invalid application_token",
            "Param" => "application_token",
            "Token" => params[:application_token]
          }
          @request_success = :error
          return
        end
      end

      def authenticate_api_user!
        @authorization = @application_integration.integration_authorizations.find_by(user_token: params[:authorization_token])
        # todo error on this if not set

        @current_api_user = @authorization.try(:user)
        unless @current_api_user
          # todo log app error
          render json: {
            "Error" => "Invalid authorization_token",
            "Param" => "authorization_token",
            "Token" => params[:authorization_token]
          }
          @request_success = :error
          return
        end
      end

      def initialize_updates_used_tracker
        @updates_used_this_request = 0
      end

      def log_api_request
        ApiRequest.create(
          application_integration:   @application_integration,
          integration_authorization: @authorization,
          result:                    @request_success || :success,
          updates_used:              @updates_used_this_request
        )
      end

      # Content page list endpoints
      Rails.application.config.content_types[:all].each do |content_type|
        define_method(content_type.name.downcase.pluralize) do
          pages = @current_api_user.send(content_type.name.downcase.pluralize)

          render json: pages.map { |page|
            {
              id:          page.id,
              name:        page.name,
              description: page.description,
              universe:    page.try(:universe).nil? ? nil : {
                id:   page.universe_id,
                name: page.universe.name
              },
              meta: {
                created_at: page.created_at,
                updated_at: page.updated_at
              }
            }
          }
        end
      end

      # Content page show endpoints
      Rails.application.config.content_types[:all].each do |content_type|
        define_method(content_type.name.downcase) do
          page = content_type.find_by(id: params[:id])

          if page && page.readable_by?(@current_api_user || User.new)
            render json: ApiContentSerializer.new(page, include_blank_fields: params.fetch(:include_blank_fields, false)).data
          else
            render json: { error: "Page not found" }
          end
        end
      end
    end
  end
end