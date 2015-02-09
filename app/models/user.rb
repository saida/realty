class User < ActiveRecord::Base         
  devise :database_authenticatable, :rememberable, :trackable, :validatable, authentication_keys: [:username]

  attr_accessor :current_password

  validates :username, presence: true, uniqueness: true
  validates :password_confirmation, presence: true

  has_many :user_category_items, dependent: :destroy
  has_many :category_items, through: :user_category_items
  has_many :categories, through: :category_items

  #accepts_nested_attributes_for :user_categories
  accepts_nested_attributes_for :user_category_items, reject_if: lambda { |i| i[:category_item_id].blank? }, allow_destroy: true

  def properties
    items = user_category_items
    if is_main
      Property.all
    elsif items.size > 0
      from = price_from
      to = price_to
      price_condition = from && to ? "BETWEEN #{from} AND #{to}" : (from ? ">= #{from}" : (to ? "<= #{to}" : '= 0'))
      arrays = []
      categories.uniq.each do |category|
        arrays << Property.joins("INNER JOIN property_category_items pci ON pci.property_id = properties.id
                       INNER JOIN user_category_items uci ON pci.category_item_id = uci.category_item_id
                       INNER JOIN category_items ci ON uci.category_item_id = ci.id")
               .where("uci.user_id = #{id} AND ci.category_id = #{ category.id }
                    AND (price1 is null or price1 #{ price_condition })
                    AND (price2 is null or price2 #{ price_condition })
                    AND (price3 is null or price3 #{ price_condition })")
      end
      arrays.inject(:'&')
    else
     []
    end
  end
  
  def properties_list
    properties.map{ |p| p.id }.join(',')
  end
end
