module AdminForms
  class FormBuilder < ::ActionView::Helpers::FormBuilder
    require_relative 'helpers/wrappers'
    include AdminForms::Helpers::Wrappers

    delegate :content_tag, :hidden_field_tag, :check_box_tag, :radio_button_tag, :button_tag, :link_to, :to => :@template

    def error_messages
      if object.try(:errors) and object.errors.full_messages.any?
        content_tag(:div, :class => 'alert alert-block alert-error validation-errors') do
          content_tag(:h4, I18n.t('admin_forms.errors.header', :model => object.class.model_name.human), :class => 'alert-heading') +
          content_tag(:ul) do
            object.errors.full_messages.map do |message|
              content_tag(:li, message)
            end.join('').html_safe
          end
        end
      else
        '' # return empty string
      end
    end

    %w(
      select
      collection_select
      country_select
      datetime_select
      date_select
      time_select
      time_zone_select

      email_field
      file_field
      number_field
      password_field
      phone_field
      range_field
      search_field
      telephone_field
      text_area
      text_field
      url_field
    ).each do |method_name|
      define_method(method_name) do |name, *raw_args, &proc|
        # Special case for select
        if method_name == 'select' or method_name == 'country_select'
          while raw_args.length < 3
            raw_args << {}
          end
        end

        options = {}
        html_options = {}

        if raw_args.length > 0
          if raw_args[-1].is_a?(Hash) && raw_args[-2].is_a?(Hash)
            html_options = raw_args[-1]
            options = raw_args[-2]
          elsif raw_args[-1].is_a?(Hash)
            options = raw_args[-1]
          end
        end

        # Add options hash to argument array if its empty
        raw_args << options if raw_args.length == 0

        if options.delete(:wrapper) == false
          options[:class]||= "form-control"
          super(name, *raw_args)
        else
          @name = name
          @field_options = field_options(options)
          @field_options[:class]||= "form-control"
          @args = options
          options.delete(:field_class)

          form_group_div do
            label_field + input_div do
              options.merge!(@field_options.merge(required_attribute))
              input_append = (options[:append] || options[:prepend] || options[:append_button]) ? true : nil
              res = extras(input_append) {super(name, *raw_args)}
              res = (res + content_tag("span", &proc)).html_safe if proc
              res
            end
          end
        end
      end
    end

    def field(name, *raw_args, &block)
      options = {}
      html_options = {}
      if raw_args.length > 0
        if raw_args[-1].is_a?(Hash) && raw_args[-2].is_a?(Hash)
          html_options = raw_args[-1]
          options = raw_args[-2]
        elsif raw_args[-1].is_a?(Hash)
          options = raw_args[-1]
        end
      end
      @name = name
      @field_options = field_options(options)
      @field_options[:class]||= "form-control"
      @args = options
      form_group_div do
        label_field + input_div do
          options.merge!(@field_options.merge(required_attribute))
          input_append = (options[:append] || options[:prepend] || options[:append_button]) ? true : nil
          extras(input_append) do
            yield
          end
        end
      end
    end

    def check_box(name, args = {}, checked_value = "1", unchecked_value = "0")
      @name = name
      @field_options = field_options(args)
      @args = args

      form_group_div do
        input_div do
          @field_options.merge!(required_attribute)
          if @field_options[:label] == false || @field_options[:label] == ''
            extras { super(name, @args.merge(@field_options)) }
          else
            klasses = 'checkbox'
            klasses << ' inline' if @field_options.delete(:inline) == true
            @args.delete :inline
            label(@name, :class => klasses) do
              extras { super(name, @args.merge(@field_options), checked_value, unchecked_value) + (@field_options[:label].blank? ? human_attribute_name : @field_options[:label])}
            end
          end
        end
      end
    end

    def check_box_field(name, args = {}, checked_value = "1", unchecked_value = "0")
      field(name) do
        check_box name, label: "&nbsp;".html_safe
      end
    end

    def radio_buttons(name, values = {}, opts = {})
      @name = name
      @field_options = @options.slice(:namespace, :index).merge(opts.merge(required_attribute))
      form_group_div do
        label_field + input_div do
          content_tag(:div, class: "radio-list") do
            klasses = 'radio'
            klasses << '-inline' if @field_options.delete(:inline) == true

            buttons = values.map do |text, value|
              radio_options = @field_options
              if value.is_a? Hash
                radio_options = radio_options.merge(value)
                value = radio_options.delete(:value)
              end

              label("#{@name}_#{value}", :class => klasses) do
                radio_button(name, value, radio_options) + text
              end
            end.join('')
            buttons << extras
            buttons.html_safe
          end
        end
      end
    end

    def collection_check_boxes(attribute, records, record_id, record_name, args = {})
      @name = attribute
      @field_options = field_options(args)
      @args = args

      form_group_div do
        label_field + input_div do
          options = @field_options.except(*ADMIN_OPTIONS).merge(required_attribute)
          # Since we're using check_box_tag() we may have to lookup the instance ourselves
          instance = object || @template.instance_variable_get("@#{object_name}")
          boxes = records.collect do |record|
            options[:id] = "#{object_name}_#{attribute}_#{record.send(record_id)}"
            checkbox = check_box_tag("#{object_name}[#{attribute}][]", record.send(record_id), [instance.send(attribute)].flatten.include?(record.send(record_id)), options)

            content_tag(:label, :class => ['checkbox', ('inline' if @field_options[:inline])].compact) do
              checkbox + record.send(record_name)
            end
          end.join('')
          boxes << extras
          boxes.html_safe
        end
      end
    end

    def collection_radio_buttons(attribute, records, record_id, record_name, args = {})
      @name = attribute
      @field_options = field_options(args)
      @args = args

      form_group_div do
        label_field + input_div do
          options = @field_options.merge(required_attribute)
          buttons = records.collect do |record|
            radiobutton = radio_button(attribute, record.send(record_id), options)
            content_tag(:label, :class => ['radio', ('inline' if @field_options[:inline])].compact) do
              radiobutton + record.send(record_name)
            end
          end.join('')
          buttons << extras
          buttons.html_safe
        end
      end
    end

    def uneditable_input(name, args = {})
      @name = name
      @field_options = field_options(args)
      @args = args

      form_group_div do
        label_field + input_div do
          extras do
            value = @field_options.delete(:value)
            @field_options[:class] = [@field_options[:class], 'uneditable-input'].compact

            content_tag(:span, @field_options) do
              value || object.send(@name.to_sym) rescue nil
            end
          end
        end
      end
    end

    def button(name = nil, args = {})
      name, args = nil, name if name.is_a?(Hash)
      @name = name
      @field_options = field_options(args)
      @args = args

      @field_options[:class] ||= 'btn'
      super(name, args.merge(@field_options))
    end

    def submit(name = nil, args = {})
      name, args = nil, name if name.is_a?(Hash)
      name = name || ("<i class='fa-check'></i> " + I18n.t('admin_forms.buttons.submit', default:'Сохранить')).html_safe
      @name = name
      @field_options = field_options(args)
      @args = args

      @field_options[:class] ||= 'btn btn-success'
      @field_options[:name]||= nil
      #super(name, args.merge(@field_options))
      button_tag(name, args.merge(@field_options))
    end

    def cancel(name = nil, args = {})
      name, args = nil, name if name.is_a?(Hash)
      name ||= I18n.t('admin_forms.buttons.cancel', default:'Отменить')
      @field_options = field_options(args)
      @field_options[:class] ||= 'btn btn-default cancel'
      @field_options[:back] ||= :back
      link_to(name, @field_options[:back], :class => @field_options[:class])
    end

    def actions(options={}, &block)
      options[:class]||= 'fluid'
      options[:offset] = 2 unless options[:offset] == false
      content_tag(:div, :class => 'form-actions ' + (options[:class] || '')) do
        if block_given?
          yield
        else
          buttons = [ submit(options[:name]), options[:cancel] != false ? cancel(options[:cancel].is_a?(String) ? options[:cancel] : nil, {class: options[:cancel_class], back: options[:back]}) : '' ].join(' ').html_safe
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

    def date_field(name, options)
      field name, options do
        content_tag(:div, class: "input-group input-medium date") do
          options[:class] = (options[:class] || "") + " date-picker form-control"
          text_field(name, {wrapper: false}.merge(options)) +
          content_tag(:span, class: "input-group-btn") do
            content_tag(:span, class: "btn btn-info", type: "button", onclick: "$('input', $(this).parent().parent()).focus()") do
              "<i class='fa-calendar'></i>".html_safe
            end
          end
        end
      end
    end

    def image_upload(name, options={})
      width = options[:width] || 0
      height = options[:height] || 0
      scale = (options[:scale] || 1).to_f
      w = (width * scale).to_i
      h = (height * scale).to_i
      default_size = (300.0 * scale).to_i
      
      if width > 0 and height > 0
        options[:label_info] = "(size %ix%ipx)" % [width, height]
        size_text = "%ix%ipx" % [width, height]
      elsif width > 0 and height == 0
        options[:label_info] = "(width %ipx)" % [width, height]
        size_text = "width+%ipx" % [width]
      elsif width == 0 and height > 0
        options[:label_info] = "(height %ipx)" % [height]
        size_text = "height+%ipx" % [height]
      else
        size_text = "any+size"
      end
      image = object.method(name).call
      has_attachment = !object.new_record? && !image.blank?
      removeable = !object.class.validators_on(name).any? {|v| v.kind_of?(ActiveModel::Validations::PresenceValidator) || v.kind_of?(Paperclip::Validators::AttachmentPresenceValidator)}

      field(name, options) do
        if !@field_options.has_key?(:help_block) && @field_options[:label]
          @field_options[:help_block] = "Upload #{@field_options[:label]}. "
          if width > 0 and height > 0
            @field_options[:help_block] << "It will be resized to %i x %i pixels." % [width, height]
          elsif width > 0 and height == 0
            @field_options[:help_block] << "It will be resized at a width of %i pixels." % [width]
          elsif width == 0 and height > 0
            @field_options[:help_block] << "It will be resized at a height of %i pixels." % [height]
          end
        end

        options[:help_block] = "Upload "
        content_tag(:div, class: "fileupload fileupload-" + (has_attachment ? 'exists' : 'new'), "data-provides" => 'fileupload') do
          content_tag(:div, "", class: "thumbnail") do
            content_tag(:div, class: "fileupload-new") do
              content_tag(:img, "", alt: "", width: w > 0 ? w : nil, height: h > 0 ? h : nil, style: w == 0 ? 'max-height:200px;' : nil, src: "http://www.placehold.it/%ix%i/EFEFEF/AAAAAA&text=%s" % [width > 0 ? width : default_size, height > 0 ? height : default_size, size_text])
            end +
            content_tag(:div, "", class: "fileupload-preview", style: "max-width:#{w > 0 ? w : 600}px; max-height:#{h > 0 ? h : 600}px; line-height: 20px;") do
              content_tag(:img, "", alt: "", src: image.url, width: w > 0 ? w : nil, height: h > 0 ? 'auto' : nil, style: w > 0 ? nil : "max-width:100%") if has_attachment
            end
          end +
          content_tag(:div) do
            content_tag(:span, class: 'btn btn-default btn-file') do
              opts = options.merge(wrapper: false, class: "default", "data-target" => "#{object.class.name}.#{name}.#{object.id}", "data-exists" => has_attachment ? true : nil)
              opts.delete("data-required") if has_attachment
              content_tag(:span, "<i class='fa-paperclip'></i> Выберите фото".html_safe, class: "fileupload-new") +
              content_tag(:span, "<i class='fa-paperclip'></i> Изменить".html_safe, class: "fileupload-exists") +
              file_field(name, opts)
            end + " &nbsp; ".html_safe +
            if removeable
              content_tag(:a, href: "#", class: 'btn btn-danger fileupload-exists', "data-dismiss" => 'fileupload') do
                content_tag(:i, "", class: "fa-trash-o") + " Удалить"
              end
            else
              ""
            end
          end
        end + (
          if respond_to?(:object) and object.respond_to?(:errors) and object.errors[@name].present?
            content_tag(:span, "ERROR!", class: "label label-danger")
          else
            #content_tag(:span, "NOTE!", class: "label label-danger", style: "font-size:75%") +
            #content_tag(:small, " Attached image thumbnail is supported in Latest Firefox, Chrome, Opera, Safari and Internet Explorer 10 only")
          end
        )
      end
    end

    def file_upload(name, options={})
      field(name, options) do
        file = object.method(name).call
        has_attachment = !object.new_record? && !file.blank?
        removeable = !object.class.validators_on(name).any? {|v| is_presence_validator(v)}

        content_tag(:div, class: 'fileupload fileupload-' + (has_attachment ? 'exists' : 'new'), "data-provides" => "fileupload") do
          content_tag(:span, class: 'btn btn-default btn-file') do
            opts = options.merge(wrapper: false, class: "default", "data-target" => "#{object.class.name}.#{name}.#{object.id}", "data-exists" => has_attachment ? true : nil)
            opts.delete("data-required") if has_attachment
            content_tag(:span, "<i class='fa-paperclip'></i> Выберите файлы".html_safe, class: "fileupload-new") +
            content_tag(:span, "<i class='fa-paperclip'></i> Изменить".html_safe, class: "fileupload-exists") +
            file_field(name, opts)
          end + " &nbsp; ".html_safe +
          content_tag(:span, has_attachment ? link_to(object["#{name}_file_name"], file.url, target: '_blank').html_safe : '', class: "fileupload-preview", style: "margin-left:5px") +
          if removeable
            content_tag(:a, "", href: "#", class: 'close fileupload-exists', style: "float: none; margin-left:5px", "data-dismiss" => 'fileupload')
          else
            ""
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

    def validate(options={})
      return unless respond_to?(:object) and object.class.respond_to?('validators_on')
      opts = {}
      opts[:rules] = {}
      tbl = object.class.model_name.singular
      attachments = {}
      t = object.class
      while t && t.respond_to?(:attachment_definitions) do
        t.attachment_definitions.each {|k, v| attachments[k] = v}
        t = t.superclass
      end
      attachments.each do |k, t|
        object.class.validators_on(k).each do |v|
          next unless valid_validator?(v) && !conditional_validators?(v)
          if v.kind_of?(ActiveModel::Validations::PresenceValidator) ||
            v.kind_of?(ActiveRecord::Validations::PresenceValidator) ||
            v.kind_of?(Paperclip::Validators::AttachmentPresenceValidator) ||
            v.options[:presence]
            if object.new_record? || !object.method(k).call.present?
              opts[:rules]["#{tbl}[#{k}]"] = {required: true}
            end
          end
        end
      end

      object.class.columns.each do |column|
        o = {}
        object.class.validators_on(column.name).each do |v|
          next unless valid_validator?(v) && !conditional_validators?(v)
          if v.kind_of?(ActiveModel::Validations::PresenceValidator) ||
            v.kind_of?(ActiveRecord::Validations::PresenceValidator) ||
            #v.kind_of?(Paperclip::Validators::AttachmentPresenceValidator) ||
            v.options[:presence]
            # presence
            o[:required] = true
          end
          if v.kind_of?(ActiveModel::Validations::FormatValidator)
            # regexp
          elsif v.kind_of?(ActiveModel::Validations::LengthValidator)
            # length
            if v.options[:is]
              o[:rangelength] = [v.options[:is], v.options[:is]]
            elsif v.options[:minimum] && v.options[:maximum]
              o[:rangelength] = [v.options[:minimum], v.options[:maximum]]
            elsif v.options[:minimum]
              o[:minlength] = v.options[:minimum]
            elsif v.options[:maximum]
              o[:maxlength] = v.options[:maximum]
            end
          elsif v.kind_of?(ActiveModel::Validations::NumericalityValidator)
            # numericality
            o[:number] = true
          end
        end

        opts[:rules]["#{tbl}[#{column.name}]"] = o if o.present?
      end
      opts[:rules].merge!(options[:rules]) if options.has_key?(:rules)
      if opts[:rules].present?
        content_tag(:script, ('$("#' + self.options[:html][:id] + '").validate(' + opts.to_json + ');').html_safe)
      else
        ""
      end
    end

  private
    def field_options(args)
      if @options
        @options.slice(:namespace, :index).merge(args)
      else
        args
      end
    end
  end
end
