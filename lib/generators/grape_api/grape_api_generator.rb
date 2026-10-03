# frozen_string_literal: true

class GrapeApiGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_api_file
    template "api.rb.tt", "app/grape/api/v1/#{file_name}.rb"
  end

  def create_entity_file
    template "entity.rb.tt", "app/entities/#{file_name}_entity.rb"
  end

  def mount_api
    inject_into_file "app/grape/api/v1/base.rb",
      "      mount API::V1::#{class_name}\n",
      after: /mount API::V1::Health\n/
  end
end
