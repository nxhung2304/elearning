# frozen_string_literal: true

module API
  class Base < Grape::API
    format :json
    default_format :json
    prefix :api

    rescue_from :all do |error|
      error!({ error: error.message }, 500)
    end

    mount API::V1::Base

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
