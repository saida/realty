class AddImageUrlToImages < ActiveRecord::Migration
  def change
    add_column :images, :image_path, :string
    add_column :images, :image_url, :string
  end
end
