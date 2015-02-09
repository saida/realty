class Category < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  has_many :category_items, dependent: :destroy
  has_many :properties, through: :category_items
  has_one :default_item, class_name: 'CategoryItem'
  
  validates :name, presence: true, uniqueness: true
    
  accepts_nested_attributes_for :category_items, reject_if: lambda { |c| c[:name].blank? }, allow_destroy: true
  
  default_scope { order(:weight) }
  scope :actives, -> { where(active: true) }
  
  def self.user_categories
    Category.actives.where("un IN ('district', 'rooms', 'service_type')")
  end
end
