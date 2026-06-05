module CoursesHelper
  def publish_toggle_link(course)
    link = course.published? ? unpublish_course_path(course) : publish_course_path(course)
    text = course.published? ? "Unpublish" : "Publish"

    link_to text, link, class: "text-sm text-slate-500 hover:text-slate-900", data: { turbo_method: :patch }
  end

  def display_course_columns(course)
    display_columns_by_type(Course.index_columns, course, {
      "category" => { path: ->(cat)  { course_category_path(cat) }, label: :name },
      "teacher"  => { path: ->(user) { user_path(user) },           label: :email }
    })
  end
end
