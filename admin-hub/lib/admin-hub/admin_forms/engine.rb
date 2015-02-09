module AdminForms
  class Engine < ::Rails::Engine
    initializer 'admin_forms.initialize' do
      config.to_prepare do
        ActiveSupport.on_load(:action_view) do
          require_relative 'helpers'

          include AdminForms::Helpers::FormHelper
          include AdminForms::Helpers::FormTagHelper
          include AdminForms::Helpers::NestedFormHelper

          # Do not wrap errors in the extra div
          ::ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
            html_tag
          end
        end
      end
    end
  end
end
