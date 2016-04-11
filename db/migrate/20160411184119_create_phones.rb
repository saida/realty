class CreatePhones < ActiveRecord::Migration
  def change
    create_table :phones do |t|
      t.string :phone
      t.integer :contact_id

      t.index :contact_id
      t.index :phone
      t.timestamps
    end
  end
end
