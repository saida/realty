class CategoryItem < ActiveRecord::Base  

  belongs_to :category
  
  has_many :property_category_items, dependent: :destroy
  has_many :properties, through: :property_category_items
  
  default_scope { order(:weight) }
  scope :actives, -> { where(active: true) }
  
  after_save :update_properties
  
  def self.selectables
    pluck(:name, :id)
  end
  
  def self.of_user(user)
    user_items = user.category_items
    if user_items.present?
      where("id IN (#{ user_items.pluck(:id).join(',') })")
    else
      all
    end
  end
    
  def update_properties
    category_un = category.un
    case category_un
    when 'status'
      properties.update_all(state: "<span class='label label-sm label-#{self.color}'>#{ self.name }</span>")
    when 'district'
      properties.update_all("address = case when landmark is null or landmark = '' or landmark = ' ' then '' else landmark || ', ' end || '#{self.name}'")
    when 'rooms', 'floor', 'floors'
      properties.update_all(category.un.to_sym => self.name)
    end
  end
    
  def destroy
    delete_properties
    super
  end

private
  def delete_properties
    category_un = category.un
    case category_un
    when 'status'
      properties.update_all(state: nil)
    when 'district'
      properties.update_all("address = landmark")
    when 'rooms', 'floor', 'floors'
      properties.update_all(category.un.to_sym => nil)
    end
  end
end
