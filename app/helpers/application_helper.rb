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

  def title_for(resource)
    if resource.respond_to?(:to_ary)
      resource.model.model_name.human(count: 2)
    else
      resource.class.model_name.human(count: 1)
    end
  end
end
