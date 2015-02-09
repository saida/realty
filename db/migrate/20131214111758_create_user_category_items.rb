class CreateUserCategoryItems < ActiveRecord::Migration
  def change
    create_table :user_category_items do |t|
      t.integer :user_id
      t.integer :category_item_id

      t.timestamps
    end
    
    add_index :user_category_items, [:user_id, :category_item_id], name: 'index_user_category_item_id'
  end
end
