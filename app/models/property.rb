# encoding: utf-8
class Property < ActiveRecord::Base
  
  attr_accessor :old_district

  belongs_to :contact
  
  has_many :property_category_items, dependent: :destroy
  has_many :category_items, through: :property_category_items
  has_many :categories, through: :category_items
  
  has_many :images, dependent: :destroy
    
  accepts_nested_attributes_for :contact, reject_if: lambda { |c| c[:name].blank? }, allow_destroy: true
  accepts_nested_attributes_for :images, reject_if: lambda { |c| c[:image].blank? && c[:image_file_name].blank? }, allow_destroy: true
  accepts_nested_attributes_for :property_category_items
    
  after_save :update_local_values
  after_commit :update_phones
  
  def item(category)
    cat = Category.find_by_un(category.to_s)
    cat = Category.find_by_id(category.to_i) unless cat
    if cat
      item = category_items.find_by_category_id(cat.id)
      item.name if item
    end
  end
  
  def item_color(category)
    item = category_items.find_by_category_id(Category.find_by_un(category.to_s).id)
    item.color if item
  end
  
  def districts
    items = category_items.where(category_id: Category.find_by_un('district').id).pluck(:name)
    items.join(', ') if items.present?
  end
  
  def service_types
    items = category_items.where(category_id: Category.find_by_un('service_type').id).order("property_category_items.id").pluck(:name)
    items
  end
  
  def self.of_user(user)
    if user.is_main
      all
    else
      where("properties.id IN (#{ user.properties_list })")
    end
  end
  
  def update_local_values
    # kee
    r = item(:rooms)
    f = item(:floor)
    fs = item(:floors)
    
    # address
    a = [landmark, districts].compact.join(', ')
    
    # status
    status = category_items.find_by_category_id(Category.find_by_un('status').id)
    if status
      s = "<span class='label label-sm label-#{status.color}'>#{ status.name }</span>"
    end
    
    Property.where(id: id).update_all(rooms: r, floor: f, floors: fs, address: a, state: s)
    
    _images = images
    
    if _images.count > 0
      
      _district_old = Russian.translit((old_district.present? ? old_district : '-').to_s.force_encoding('utf-8'))
      _district = Russian.translit((item(:district) || '-').to_s.force_encoding('utf-8'))
      _landmark_old = Russian.translit(landmark_was.to_s.gsub(/[\x00\/\\:\*\?\"<>\|]/, '').force_encoding('utf-8')).gsub(/[\xC2\xBB|\xC2\xAB]/, '').to_s.strip
      _landmark = Russian.translit(landmark.to_s.gsub(/[\x00\/\\:\*\?\"<>\|]/, '').force_encoding('utf-8')).gsub(/[\xC2\xBB|\xC2\xAB]/, '').to_s.strip
      _kee_old = "#{rooms.to_s[/\d+/]}-#{floor.to_s[/\d+/]}-#{floors.to_s[/\d+/]}"
      _kee = "#{r.to_s[/\d+/]}-#{f.to_s[/\d+/]}-#{fs.to_s[/\d+/]}"
      _price_old = [price1_was, price2_was, price3_was].reject(&:blank?).join(' ')
      _price = [price1, price2, price3].reject(&:blank?).join(' ')
      info_old = "#{_kee_old} #{_landmark_old} #{_price_old}"
      info = "#{_kee} #{_landmark} #{_price}"
      old_path = Rails.root.join('public', 'photos', _district_old, info_old, self.id.to_s)
      new_path = Rails.root.join('public', 'photos', _district, info, self.id.to_s)
      
      _images.each do |image|
        if image.image?
          filename = image.short_name  #  image.image_file_name
          old_path_with_filename = File.join(old_path, filename)
          
          if File.exists?(old_path_with_filename) && old_path_with_filename != File.join(new_path, filename)
            FileUtils.mkdir_p new_path
            FileUtils.mv old_path_with_filename, File.join(new_path) # , filename)
            
            # delete old empty folder
            if Dir[old_path.to_s + '/*'].empty?
              FileUtils.rm_rf old_path
              
              old_parent_path = File.expand_path("..", old_path)
              if Dir[old_parent_path + "/*"].empty?
                FileUtils.rm_rf old_parent_path
              end
            end
          end
          
          image.save # to update the locally saved image_urls
        end
      end
    end
  end
    
  def self.update_local_values
    CategoryItem.all.each { |i| i.update_properties }
  end  
end
