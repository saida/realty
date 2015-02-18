class Image < ActiveRecord::Base
  
  belongs_to :property
  
  Paperclip.interpolates :district do |attachment, style|
    attachment.instance.image_district
  end
    
  Paperclip.interpolates :info do |attachment, style|
    attachment.instance.image_info
  end
  
  has_attached_file :image,
                # Dropbox - very slow
                # styles: { thumb: '30x30>' },
                # storage: :dropbox,
                # dropbox_credentials: Rails.root.join("config/dropbox.yml"),
                # dropbox_visibility: 'private',
                # path: "Public/:id_:style_:filename"
                
                # Google Drive - slow and needs to refresh
                # storage: :google_drive,
                # google_drive_credentials: "#{Rails.root}/config/google_drive.yml",
                # google_drive_options: {
                #   public_folder_id: "0B6f6sgLFURAJfmNHZjZxUkZLQURmU2NuUmo4OHN0QS0tTXpGeURWekQ5Y3FBSW5JS0tXU00",
                #   path: proc { |style| "#{image.instance.id}_#{style}_#{image.original_filename}" }
                # }
                
                # /#{image.instance.image_district}/#{image.instance.image_info}/
                # path: ':rails_root/public/photos/:district/:info/:filename',
                # url: '/photos/:district/:info/:filename'
                storage: :filesystem,
                path: ':rails_root/public/attachments/:id_:style_:filename',
                url: '/attachments/:id_:style_:filename'
                
  
  validates_attachment_content_type :image, content_type: /image/
    
  def  district
    item = property.item(:district)
    item.present? ? item : '-'
  end
  
  def image_district
    Russian.translit(self.district.force_encoding('utf-8'))
  end
  
  def image_info
    property = self.property
    if property.rooms? || property.floor? || property.floors?
      kee = "#{property.rooms.to_s[/\d+/]}-#{property.floor.to_s[/\d+/]}-#{property.floors.to_s[/\d+/]}"
    else
      kee = "#{property.item(:rooms).to_s[/\d+/]}-#{property.item(:floor).to_s[/\d+/]}-#{property.item(:floors).to_s[/\d+/]}"
    end
    landmark = Russian.translit(property.landmark.force_encoding('utf-8'))
    price = [property.price1, property.price2, property.price3].reject(&:blank?).join(' ')
    "#{kee} #{landmark} #{price}"
  end
  
  # new folders of images with id
  def self.convert_to_new_path
    dir = FileUtils.mkdir_p(Rails.root.join('public', 'attachments'))[0]
    all.each do |item|
      if item.image?
        if File.exists?(item.image.path(:original))
          FileUtils.cp item.image.path(:original), File.join(dir, "#{item.id}_original_#{item.image.original_filename}")
          Rails.logger.debug item.image.original_filename
        end
      end
    end
  end
end
