module ApplicationHelper
  include Pagy::Frontend

  def add_breadcrumb(label, path = nil)
    @breadcrumbs ||= []
    @breadcrumbs << { label:, path: }
  end

  def breadcrumbs
    @breadcrumbs || []
  end

  def status_badge_color(status)
    case status
    when "active"
      "bg-green-100 text-green-800"
    when "inactive"
      "bg-gray-100 text-gray-800"
    when "deleted"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def button_classes(variant)
    case variant
    when :danger
      "rounded-full bg-red-600 px-6 py-2 text-sm font-medium text-white shadow-sm transition-shadow hover:bg-red-700 hover:shadow-md"
    when :danger_outlined
      "rounded-full border border-red-600 px-6 py-2 text-sm font-medium text-red-600 transition-colors hover:bg-red-50"
    when :primary
      "rounded-full bg-emerald-600 px-6 py-2 text-sm font-medium text-white shadow-sm transition-shadow hover:bg-emerald-700 hover:shadow-md"
    when :primary_outlined
      "rounded-full border border-emerald-600 px-6 py-2 text-sm font-medium text-emerald-600 transition-colors hover:bg-emerald-50"
    when :icon
      "rounded-full p-2 text-slate-400 transition-colors hover:bg-slate-900/5 hover:text-slate-600"
    when :icon_primary
      "rounded-full p-2 text-slate-400 transition-colors hover:bg-emerald-50 hover:text-emerald-600"
    when :icon_danger
      "rounded-full p-2 text-slate-400 transition-colors hover:bg-red-50 hover:text-red-600"
    when :icon_filled
      "rounded-full bg-emerald-600 p-2 text-white shadow-sm transition-shadow hover:bg-emerald-700 hover:shadow-md"
    end
  end

  def title_for(resource)
    if resource.respond_to?(:to_ary)
      resource.model.model_name.human(count: 2)
    else
      resource.class.model_name.human(count: 1)
    end
  end
end
