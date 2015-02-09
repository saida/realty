class PropertyCategoryItem < ActiveRecord::Base
  belongs_to :property
  belongs_to :category_item
end
