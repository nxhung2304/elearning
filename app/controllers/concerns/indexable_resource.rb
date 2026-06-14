module IndexableResource
  extend ActiveSupport::Concern

  included do
    before_action :set_collection, only: :index
  end

  private

  def set_collection
    @q = resource_collection.ransack(params[:q])

    scope = @q.result(distinct: true)
    scope = scope.includes(includes_associations)

    @pagy, records = pagy(scope)

    records = records.kept if records.respond_to?(:kept)

    instance_variable_set("@#{controller_name}", records)
  end

  # Returns authorized scope set by CanCanCan's load_and_authorize_resource
  # Example: @courses, @users,...
  def resource_collection
    instance_variable_get("@#{controller_name}")
  end

  # Eager load all belongs_to associations to avoid N+1
  def includes_associations
    resource_class.reflect_on_all_associations(:belongs_to).map(&:name)
  end

  # Infers model class from controller path, e.g. Admin::CoursesController → Admin::Course
  def resource_class
    controller_path.classify.constantize
  end
end
