class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name
      t.string :un
      t.string :slug
      
      t.integer :weight, default: 0
      t.boolean :active, default: true

      t.timestamps
      
      t.index :slug,  unique: true
      t.index :un,    unique: true
      t.index [:weight, :active]
    end
  end
end
