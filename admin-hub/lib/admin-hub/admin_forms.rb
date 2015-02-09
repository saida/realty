# encoding: utf-8
require 'admin-hub/admin_forms/engine' if defined?(::Rails)

module AdminForms
  require_relative 'admin_forms/engine'
  require_relative 'admin_forms/form_builder'

  class << self
    def default_form_builder
      @default_form_builder ||= AdminForms::FormBuilder
    end

    def default_form_builder=(builder)
      @default_form_builder = builder
    end
  end
end
