module CoursesHelper
  def publish_toggle_link(course)
    link = course.published? ? unpublish_course_path(course) : publish_course_path(course)
    text = course.published? ? "Unpublish" : "Publish"

    link_to text, link, class: "text-sm text-slate-500 hover:text-slate-900", data: { turbo_method: :patch }
  end

  def course_column_links
    {
      "category" => { path: ->(cat)  { course_category_path(cat) }, label: :name },
      "teacher"  => { path: ->(user) { user_path(user) },           label: :email }
    }
  end
end
