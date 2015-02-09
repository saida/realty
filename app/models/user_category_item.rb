class UserCategoryItem < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :category_item
end
