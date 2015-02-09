class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.text :info
      t.boolean :active, default: true
      
      t.index :info
      t.timestamps
    end
  end
end
