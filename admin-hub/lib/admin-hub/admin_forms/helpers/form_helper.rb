module AdminForms
  module Helpers
    module FormHelper
      def admin_form_for(record, options = {}, &block)
        options[:builder]||= AdminForms.default_form_builder
        options[:label_class]||= "col-md-2"
        options[:field_class]||= "col-md-6"

        form_options = options.deep_dup
        options[:summary_errors] = form_options.has_key?(:summary_errors)
        form_options.delete(:summary_errors)
        form_options[:html]||= {}
        form_options[:html][:class]||= ""
        form_options[:html][:class] << " form-horizontal" unless options[:horizontal] == false

        form_for(record, form_options) do |f|
          f.content_tag(:div, class: "form-body") do
            f.content_tag(:div,
              "You have some form errors. Please check below.".html_safe, class: "alert alert-danger display-hide",
              style: f.object && f.object.respond_to?(:errors) && !options[:summary_errors] && !options.has_key?(:errors) && f.object.errors.present? ? "display:block" : nil
            ) +
            if f.object.respond_to?(:errors) and options[:summary_errors]
              f.error_messages.html_safe + capture(f, &block).html_safe
            else
              capture(f, &block).html_safe
            end
          end
        end
      end

      def admin_fields_for(record_name, record_object = nil, options = {}, &block)
        options[:label_class]||= "col-md-2"
        options[:field_class]||= "col-md-6"
        options[:builder]||= AdminForms.default_form_builder
        fields_for(record_name, record_object, options, &block)
      end
    end
  end
end
