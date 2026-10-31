# frozen_string_literal: true

module Api
  class Base < Grape::API
    format :json
    default_format :json
    prefix :api

    rescue_from Grape::Exceptions::ValidationErrors do |error|
      error!(Api::ErrorCodes.body(Api::ErrorCodes::INVALID_PARAMS, error.message), 422)
    end

    rescue_from :all do |error|
      error!(Api::ErrorCodes.body(Api::ErrorCodes::INTERNAL_ERROR, error.message), 500)
    end

    mount Api::V1::Base

    helpers do
      def current_user
        @current_user ||= env["warden"].authenticate(scope: :user)
      end

      def authenticate!
        error!(Api::ErrorCodes.body(Api::ErrorCodes::UNAUTHORIZED, "Unauthorized"), 401) unless current_user
      end
    end

    if ENV["SWAGGER_ENABLED"] == "true"
      add_swagger_documentation(
        api_version: "v1",
        base_path: "/",
        mount_path: "/swagger_doc",
        info: { title: "API" }
      )
    end
  end
end
