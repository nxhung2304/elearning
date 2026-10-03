# frozen_string_literal: true

class BaseEntity < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt.iso8601 }

  expose :id

  with_options(format_with: :iso_timestamp) do
    expose :created_at
    expose :updated_at
  end
end
