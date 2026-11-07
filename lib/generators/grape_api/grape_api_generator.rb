# frozen_string_literal: true

class GrapeApiGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  ACTIONS = %w[index show create update destroy].freeze

  class_option :actions, type: :array, default: ACTIONS

  def create_api_file
    template "api.rb.tt", "app/grape/api/v1/#{file_name}.rb"
  end

  def create_entity_file
    template "entity.rb.tt", "app/entities/#{file_name}_entity.rb"
  end

  def mount_api
    inject_into_file "app/grape/api/v1/base.rb",
      "      mount Api::V1::#{class_name}\n",
      after: /mount Api::V1::Health\n/
  end

  private

    def action?(name)
      options[:actions].include?(name)
    end

    def first_action?(name)
      ACTIONS.find { |action| action?(action) } == name
    end
end
