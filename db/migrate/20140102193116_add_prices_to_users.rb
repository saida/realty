class AddPricesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :price_from, :integer
    add_column :users, :price_to, :integer
    add_column :users, :is_main, :boolean, default: false
    
    user = User.find_by_username('admin')
    if user
      user.update_attributes!(is_main: true, password: '12345678', password_confirmation: '12345678')
    end
  end
end
