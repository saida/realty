
module AdminHub
  module DeleteAttachment
    #
    # Usage:
    # class Admin::BaseController < ApplicationController
    #   include Resources::DeleteAttachment
    # end
    #
    # Parameters:
    #  id - [Model].[field].[id]
    #    for example: "Page.image1.3" same as Page.find(3).image1.destroy
    #
    # it will return nothing
    #
    def delete_attachment
      klassname, item, id = (params[:target] || '').split('.')
      klass = Object.const_get(klassname)
      if klass and klass.respond_to?(:has_attachment) and klass.respond_to?(:attachment_definitions) and klass.attachment_definitions[item.to_sym]
        if not klass.validators_on(item).any? {|v| v.kind_of?(Paperclip::Validators::AttachmentPresenceValidator)}
          object = klass.find(id)
          if object
            attachment = object.method(item).call
            if attachment and !attachment.blank?
              attachment.destroy
              object.save!
            end
          end
        end
      end
      render nothing: true
    end
  end
end
