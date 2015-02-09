module AdminHub
  module AttachmentHelper
    #
    # class Model < ActiveRecord::Base
    #   has_image :image, required: true, index_style: :thumb, styles: {...}
    #   has_attachment :pdf, required: true
    # end
    #
    # additional parameters:
    #  required - validates presence
    #  index_style - style used in datatables request
    #
    def has_image(name, options = {})
      options[:type] = :image
      unless options[:default_style]
        if options[:styles].is_a?(Hash) and options[:styles].size == 1
          options[:default_style] = options[:styles].keys[0]
        end
      end
      has_attachment name, options
    end

    def has_video(name, options = {})
      options[:type] = :video
      has_attachment name, options
    end
    
    def has_audio(name, options = {})
      options[:type] = :audio
      has_attachment name, options
    end

    def has_pdf(name, options = {})
      options[:type] = :audio
      options[:attachment] = true unless options.has_key?(:attachment)
      has_attachment name, options
    end

    def has_attachment(name, options = {})
      type = options[:type] || :data

      attachment_path = "#{table_name}/:attachment/:id/" + (type == :image ? ":style/" : "") + ":filename"

      if Rails.env.production?
        options[:path]||= attachment_path
        options[:url] ||= attachment_path
        options[:s3_headers]||= { 'Content-Disposition' => "attachment" } if options[:attachment]
      else
        options[:path]||= ":rails_root/public/system/#{attachment_path}"
        options[:url] ||= "/system/#{attachment_path}"
      end

      has_attached_file name, options

      validate_options = {}
      #validate_options[:presence] = true if options[:required]
      validate_options[:content_type] = {content_type: /^image\//} if type == :image
      validate_options[:content_type] = {content_type: /^video\//} if type == :video
      validate_options[:content_type] = {content_type: /^audio\//} if type == :audio
      validate_options[:content_type] = {content_type: "application/pdf"} if type == :pdf

      validates_attachment name, validate_options if validate_options.length > 0
      validates_presence_of name if options[:required]
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend AdminHub::AttachmentHelper
end
