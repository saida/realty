module AdminForms
  module Helpers
    module FormTagHelper
      include AdminForms::Helpers::Wrappers

      def admin_form_tag(url_for_options = {}, options = {}, &block)
        form_tag(url_for_options, options, &block)
      end

      %w(
        check_box_tag
        email_field_tag
        file_field_tag
        image_submit_tag
        number_field_tag
        password_field_tag
        phone_field_tag
        radio_button_tag
        range_field_tag
        search_field_tag
        select_tag
        telephone_field_tag
        text_area_tag
        text_field_tag
        url_field_tag
      ).each do |method_name|
        # prefix each method with admin_*
        define_method("admin_#{method_name}") do |name, *args|
          @name = name
          @field_options = field_options(args)
          @field_options[:class]||= "form-control"
          @args = args

          form_group_div do
            label_field + input_div do
              extras { send(method_name.to_sym, name, *(@args << @field_options)) }
            end
          end
        end
      end

      def uneditable_input_tag(name, *args)
        @name = name
        @field_options = field_options(args)
        @args = args

        form_group_div do
          label_field + input_div do
            extras do
              content_tag(:span, :class => 'uneditable-input') do
                @field_options[:value]
              end
            end
          end
        end
      end

      def admin_button_tag(name = nil, *args)
        @name = name
        @field_options = field_options(args)
        @args = args

        @field_options[:class] ||= 'btn btn-primary'
        button_tag(name, *(args << @field_options))
      end

      def admin_submit_tag(name=nil, *args)
        name||= ("<i class='fa-check'></i> " + I18n.t('admin_forms.buttons.submit', default:'Сохранить')).html_safe
        @name = name
        @field_options = field_options(args)
        @args = args

        @field_options[:class] ||= 'btn btn-success'
        @field_options[:name]||= nil
        button_tag(name, *(args << @field_options))
      end

      def admin_cancel_tag(*args)
        @field_options = field_options(args)
        @field_options[:class] ||= 'btn btn-default cancel'
        link_to(I18n.t('admin_forms.buttons.cancel', default:'Отменить'), (@field_options[:back] || :back), @field_options)
      end

      def admin_actions(options={}, &block)
        options[:class]||= 'fluid'
        options[:offset] = 2 unless options[:offset] == false
        content_tag(:div, :class => 'form-actions ' + (options[:class] || '')) do
          if block_given?
            yield
          else
            buttons = [ admin_submit_tag(options[:name]), options[:cancel] != false ? admin_cancel_tag : '' ].join(' ').html_safe
            if options[:offset]
              content_tag(:div, class: "col-md-offset-#{options[:offset]}") do
                buttons
              end
            else
              buttons
            end
          end
        end
      end

    private
      def field_options(args)
        if @options
          @options.slice(:namespace, :index).merge(args.extract_options!)
        else
          args.extract_options!
        end
      end
    end
  end
end
