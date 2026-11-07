# frozen_string_literal: true

class CourseCategoriesEntity < BaseEntity
  expose :name, documentation: { type: "String" }
  expose :parent_id, documentation: { type: "Integer" }

  unexpose :created_at
  unexpose :updated_at
end
