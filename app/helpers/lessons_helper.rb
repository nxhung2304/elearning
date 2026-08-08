module LessonsHelper
  LESSON_TYPE_ICON_PATHS = {
    "video" => "M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
    "text"  => "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
    "mixed" => "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
  }.freeze

  # Inline Material-outline icon reflecting the lesson type (video / text / mixed).
  def lesson_type_icon(lesson, css_class: "h-5 w-5")
    tag.svg(class: css_class, fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
      tag.path(
        d: LESSON_TYPE_ICON_PATHS.fetch(lesson.lesson_type, LESSON_TYPE_ICON_PATHS["text"]),
        stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2"
      )
    end
  end

  # Human-friendly duration, e.g. "1h 5m", "8m". Returns "—" when unknown/zero.
  def format_duration(seconds)
    seconds = seconds.to_i
    return "—" if seconds.zero?

    minutes = seconds / 60
    hours = minutes / 60
    minutes %= 60

    parts = []
    parts << "#{hours}h" if hours.positive?
    parts << "#{minutes}m" if minutes.positive?
    parts << "#{seconds}s" if parts.empty?
    parts.join(" ")
  end

  # A lesson is locked for a viewer who is not enrolled, cannot manage it,
  # and the lesson is not a free preview.
  def lesson_locked?(lesson, enrolled:, can_manage:)
    !(enrolled || lesson.is_preview || can_manage)
  end
end
