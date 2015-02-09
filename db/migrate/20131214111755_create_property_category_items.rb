class CreatePropertyCategoryItems < ActiveRecord::Migration
  def change
    create_table :property_category_items do |t|
      t.integer :property_id
      t.integer :category_item_id

      t.timestamps
      
      t.index :property_id
      t.index :category_item_id
    end
    
    add_index :property_category_items, [:property_id, :category_item_id], name: 'index_property_category_item_id'
  end
end
