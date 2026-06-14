module DiscardableResource
  extend ActiveSupport::Concern

  included do
    before_action :ensure_kept, only: %i[show edit update destroy]
  end

  private

    def ensure_kept
      resource = instance_variable_get(:"@#{controller_name.singularize}")
      raise ActiveRecord::RecordNotFound if resource&.respond_to?(:discarded?) && resource.discarded?
    end
end
