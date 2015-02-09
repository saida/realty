class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.attachment :image
      t.integer :property_id
      t.string :title
      t.text :description
      t.integer :weight, default: 0

      t.timestamps
      
      t.index :property_id
    end
  end
end
