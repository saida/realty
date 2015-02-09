begin
  require 'nested_form/builder_mixin'

  module NestedForm
    class AdminBuilder < ::AdminForms::FormBuilder
      include ::NestedForm::BuilderMixin
    end
  end

  module AdminForms
    module Helpers
      module NestedFormHelper
        def admin_nested_form_for(*args, &block)
          options = args.extract_options!.reverse_merge(:builder => NestedForm::AdminBuilder)
          form_for(*(args << options), &block) << after_nested_form_callbacks
        end
      end
    end
  end

rescue LoadError => e
  module AdminForms
    module Helpers
      module NestedFormHelper
        def admin_nested_form_for(*args, &block)
          raise 'nested_form was not found. Is it in your Gemfile?'
        end
      end
    end
  end
end
