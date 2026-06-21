module SectionsHelper
  def section_column_links
    {
      "course" => { path: ->(c) { course_path(c) }, label: :title }
    }
  end
end
