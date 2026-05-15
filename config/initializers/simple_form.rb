SimpleForm.setup do |config|
  config.wrappers :default, class: "form-control w-full mb-5" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "label label-text font-medium text-sm font-semibold text-gray-700 mb-2 block"
    b.use :input, class: "input input-bordered w-full h-11 px-3.5 py-2 bg-white border border-gray-300 rounded-md text-sm focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition", error_class: "input-error"
    b.use :full_error, wrap_with: { class: "label label-text-alt text-error" }
    b.use :hint, wrap_with: { class: "label label-text-alt text-base-content/60" }
  end

  config.wrappers :check_boxes, tag: :div, class: "form-control" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label_input, class: "label cursor-pointer justify-start gap-2"
    b.use :full_error, wrap_with: { class: "label label-text-alt text-error" }
    b.use :hint, wrap_with: { class: "label label-text-alt text-base-content/60" }
  end

  config.wrappers :select, class: "form-control w-full" do |b|
    b.use :html5
    b.use :label, class: "label label-text font-medium"
    b.use :input, class: "select select-bordered w-full", error_class: "select-error"
    b.use :full_error, wrap_with: { class: "label label-text-alt text-error" }
    b.use :hint, wrap_with: { class: "label label-text-alt text-base-content/60" }
  end

  config.wrappers :textarea, class: "form-control w-full" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :readonly
    b.use :label, class: "label label-text font-medium"
    b.use :input, class: "textarea textarea-bordered w-full", error_class: "textarea-error"
    b.use :full_error, wrap_with: { class: "label label-text-alt text-error" }
    b.use :hint, wrap_with: { class: "label label-text-alt text-base-content/60" }
  end

  config.default_wrapper = :default
  config.browser_validations = false
  config.boolean_style = :nested
  config.button_class = "btn btn-primary"
  config.error_notification_tag = :div
  config.error_notification_class = "alert alert-error mb-4"

  config.input_mappings = {
    /text/ => :textarea,
    /password/ => :password,
    /select/ => :select,
    /check_box/ => :check_boxes
  }
end
