module ApplicationHelper
  include Pagy::Frontend

  def add_breadcrumb(label, path = nil)
    @breadcrumbs ||= []
    @breadcrumbs << { label:, path: }
  end

  def breadcrumbs
    @breadcrumbs || []
  end
end
