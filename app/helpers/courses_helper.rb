module CoursesHelper
  def publish_toggle_link(course)
    link = course.published? ? unpublish_course_path(course) : publish_course_path(course)
    text = course.published? ? "Unpublish" : "Publish"

    link_to text, link, class: "text-sm text-slate-500 hover:text-slate-900", data: { turbo_method: :patch }
  end

  # Lessons shown in the curriculum for a section, ordered by position.
  # Students only see published lessons; teachers/admins also see drafts.
  # Operates on already-loaded lessons to avoid N+1 queries.
  def curriculum_lessons(section, can_manage:)
    section.lessons
           .reject(&:discarded?)
           .select { |lesson| lesson.is_published || can_manage }
           .sort_by(&:position)
  end

  # Total formatted duration for a collection of lessons, or nil when unknown/zero.
  def section_duration(lessons)
    total = lessons.sum { |lesson| lesson.duration_seconds.to_i }
    format_duration(total) if total.positive?
  end

  def course_column_links
    {
      "category" => { path: ->(cat)  { course_category_path(cat) }, label: :name },
      "teacher"  => { path: ->(user) { user_path(user) },           label: :email }
    }
  end
end
