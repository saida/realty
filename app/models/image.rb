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
  
  Paperclip.interpolates :property_id do |attachment, style|
    attachment.instance.property_id
  end

  Paperclip.interpolates :name do |attachment, style|
    attachment.instance.short_name
  end
  
  has_attached_file :image,
                path: ':rails_root/public/photos/:district/:info/:property_id/:name',
                url: '/photos/:district/:info/:property_id/:name'
  
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
  
  def self.add_property_id_to_image_paths
    all.each do |image|
      if image.image?
        
        old_path_with_filename = image.image_path
        filename = image.short_name
        new_path = image.image.path.to_s.sub("/#{filename}", "")
        
        if File.exists?(old_path_with_filename) && old_path_with_filename != File.join(new_path, filename)
          puts "Adding ID to image path: #{new_path}"
          FileUtils.mkdir_p new_path
          FileUtils.mv old_path_with_filename, File.join(new_path)
        end

        image.save # to update the locally saved image_urls
      end
    end
  end
  
  def self.move_images
    all.each do |image|
      path = image.image_path.to_s
      unless File.exists?(path)
        old_path_with_filename = path.gsub("/#{image.property_id}", "")
        if File.exists?(old_path_with_filename)
          puts "Moving #{old_path_with_filename}..."
          new_path = path.gsub(Regexp.new("/#{image.property_id}.*"), "") + "/#{image.property_id}"
          FileUtils.mkdir_p new_path
          FileUtils.mv old_path_with_filename, File.join(new_path)
        end
      end
    end
  end
end
