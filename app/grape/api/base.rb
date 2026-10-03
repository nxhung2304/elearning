# frozen_string_literal: true

module Api
  class Base < Grape::API
    format :json
    default_format :json
    prefix :api

    rescue_from :all do |error|
      error!({ error: error.message }, 500)
    end

    mount Api::V1::Base

    helpers do
      def current_user
        @current_user ||= User.authorize!(env)
      end

      def authenticate!
        error!("401 Unauthorized", 401) unless current_user
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
