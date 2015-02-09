class CreateCategoryItems < ActiveRecord::Migration
  def change
    create_table :category_items do |t|
      t.integer :category_id
      t.string :name
      t.string :color
      
      t.integer :weight, default: 0
      t.boolean :active, default: true

      t.timestamps
      
      t.index :weight
      t.index [:weight, :active]
      t.index :category_id
    end
  end
end
