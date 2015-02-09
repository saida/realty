class AddDefaultItemIdToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :default_item_id, :integer
  end
end
