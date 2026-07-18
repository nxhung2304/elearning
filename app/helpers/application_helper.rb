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
      "rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-100"
    when :primary
      "rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm font-medium text-emerald-600 hover:bg-emerald-100"
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
