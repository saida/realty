class AddWeightToPropertyCategoryItems < ActiveRecord::Migration
  def change
    add_column :property_category_items, :weight, :integer
  end
end
