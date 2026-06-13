module ApplicationHelper
  include Pagy::Frontend

  def add_breadcrumb(label, path = nil)
    @breadcrumbs ||= []
    @breadcrumbs << { label:, path: }
  end

  def breadcrumbs
    @breadcrumbs || []
  end

  def display_columns_by_type(cols, resource, links = {})
    cols.each do |col|
      if col == "status"
        concat content_tag(:td, render("shared/status_badge", status: resource.status), class: "px-4 py-3")
        next
      end

      if links.key?(col)
        assoc = resource.public_send(col)
        url   = links[col][:path].call(assoc)
        label = assoc.public_send(links[col][:label])
        concat content_tag(:td, link_to(label, url), class: "px-4 py-3 underline hover:text-blue-800")
        next
      end

      concat content_tag(:td, resource.public_send(col), class: "px-4 py-3")
    end
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
end
