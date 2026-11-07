# frozen_string_literal: true

module Api
  module V1
    class Courses < Api::Base
      helpers do
        def course_filter_params
          declared(params)[:q]
        end

        def present_published_courses(filter_params)
          courses = Course.by_published.ordered_by_published_at.includes(:category, :teacher).ransack(filter_params).result
          present_paginated(courses, with: CoursesEntity)
        end
      end

      resource :courses do
        desc "List courses"
        params do
          optional :page, type: Integer, default: 1, values: (1..)
          optional :q, type: Hash, desc: "Search and filter queries" do
            optional :level_eq, type: Integer, values: Course.levels.values
            optional :category_id_eq, type: Integer
            optional :title_i_cont, type: String
          end
        end

        get do
          authenticate!

          if course_filter_params.present? && course_filter_params[:category_id_eq].present?
            category_id = course_filter_params[:category_id_eq]
            course_category = CourseCategory.kept.find_by(id: category_id)

            if course_category.blank?
              present_paginated(Course.none, with: CoursesEntity) and return
            else
              subtree_ids = course_category.subtree.kept.pluck(:id)
              filters = course_filter_params.to_h
              filters.delete("category_id_eq")
              filters[:category_id_in] = subtree_ids

              present_published_courses(filters)
            end

          else
            present_published_courses(course_filter_params)
          end
        end
      end
    end
  end
end
