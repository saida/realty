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
    landmark = Russian.translit(property.landmark.force_encoding('utf-8'))
    price = [property.price1, property.price2, property.price3].reject(&:blank?).join(' ')
    "#{kee} #{landmark} #{price}"
  end
  
  has_attached_file :image,
                path: ':rails_root/public/photos/:district/:info/:filename',
                url: '/photos/:district/:info/:filename'
  
  validates_attachment_content_type :image, content_type: /image/
  
  def  district
    item = property.item(:district)
    item.present? ? item : '-'
  end
end
