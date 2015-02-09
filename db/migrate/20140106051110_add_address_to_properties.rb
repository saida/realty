class AddAddressToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :address, :text
    add_column :properties, :state, :string
    add_column :properties, :rooms, :string
    add_column :properties, :floor, :string
    add_column :properties, :floors, :string
    
    add_column :contacts, :properties_count, :integer
  end
end
