# frozen_string_literal: true

module Api
  module V1
    class CourseCategories < Api::Base
      resource :course_categories do
        desc "List course_categories"
        get do
          authenticate!

          course_categories = CourseCategory.kept.order(:position)

          present :data, course_categories, with: CourseCategoriesEntity
        end
      end
    end
  end
end
