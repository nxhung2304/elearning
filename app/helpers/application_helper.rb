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

      value = resource.public_send(col)
      display = value.is_a?(ActiveRecord::Base) ? infer_record_label(value) : value
      concat content_tag(:td, display, class: "px-4 py-3")
    end
  end

  def display_resource_columns(resource, with_links: true)
    method_name = :"#{resource.model_name.singular}_column_links"
    links = with_links && respond_to?(method_name) ? public_send(method_name) : {}
    display_columns_by_type(resource.class.index_columns, resource, links)
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

  private

    def infer_record_label(record)
      %i[name title email].find { |m| record.respond_to?(m) }
                          &.then { |m| record.public_send(m) } || record.to_s
    end
end
