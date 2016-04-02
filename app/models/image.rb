# encoding: utf-8
class Image < ActiveRecord::Base
  
  belongs_to :property
  
  Paperclip.interpolates :district do |attachment, style|
    Russian.translit(attachment.instance.district.force_encoding('utf-8'))
  end
    
  Paperclip.interpolates :info do |attachment, style|
    property = attachment.instance.property
    if property.rooms? || property.floor? || property.floors?
      kee = "#{property.rooms.to_s[/\d+/]}-#{property.floor.to_s[/\d+/]}-#{property.floors.to_s[/\d+/]}"
    else
      kee = "#{property.item(:rooms).to_s[/\d+/]}-#{property.item(:floor).to_s[/\d+/]}-#{property.item(:floors).to_s[/\d+/]}"
    end
    landmark = Russian.translit(property.landmark.to_s.gsub(/[\x00\/\\:\*\?\"<>\|]/, '').force_encoding('utf-8')).gsub(/[\xC2\xBB|\xC2\xAB]/, '').to_s.strip
    price = [property.price1, property.price2, property.price3].reject(&:blank?).join(' ')
    "#{kee} #{landmark} #{price}"
  end

  Paperclip.interpolates :name do |attachment, style|
    # f = attachment.original_filename
    # if File.basename(f).length > 30
    #   e = File.extname(f)
    #   b = File.basename(f).truncate(30, omission: '')
    #   return b.to_s + e.to_s
    # else
    #   return f
    # end
    attachment.instance.short_name
  end
  
  has_attached_file :image,
                path: ':rails_root/public/photos/:district/:info/:name',
                url: '/photos/:district/:info/:name'
  
  validates_attachment_content_type :image, content_type: /image/
  
  after_save :update_image_url
  
  def  district
    item = property.item(:district)
    item.present? ? item : '-'
  end

  def short_name
    f = self.image_file_name
    if File.basename(f).length > 30
      e = File.extname(f)
      b = File.basename(f).truncate(30, omission: '')
      return b.to_s + e.to_s
    else
      return f
    end
  end
  
  def update_image_url
    img_path = self.image.path
    unless self.image? && self.image_path == img_path
      self.image_path = img_path
      self.image_url = self.image.url(:original, false)
      self.save
    end
  end
end
