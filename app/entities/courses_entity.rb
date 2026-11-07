# frozen_string_literal: true

class CoursesEntity < BaseEntity
  expose :title, documentation: { type: "String" }
  expose :slug, documentation: { type: "String" }
  expose :level, documentation: { type: "String" }
  expose :price, documentation: { type: "String" }
  expose :total_lessons, documentation: { type: "Integer" }

  expose :category do |course|
    { id: course.category.id, name: course.category.name }
  end

  expose :teacher do |course|
    { id: course.teacher.id, name: course.teacher.name }
  end

  unexpose :created_at
  unexpose :updated_at
end
