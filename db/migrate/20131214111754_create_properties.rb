class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.integer :contact_id
      
      t.integer :price1
      t.integer :price2
      t.integer :price3
      t.text :landmark
      t.text :more_info
      t.date :last_call_date
      t.date :request_date
      t.date :clear_date
      t.date :rental_date
      t.boolean :viewed, default: false
      
      t.timestamps
      
      t.index :contact_id
    end
  end
end
