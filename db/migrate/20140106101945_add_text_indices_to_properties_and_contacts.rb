class AddTextIndicesToPropertiesAndContacts < ActiveRecord::Migration
  def up
    execute "CREATE INDEX idx_properties_on_more_info ON properties (more_info COLLATE NOCASE)"
    execute "CREATE INDEX idx_properties_on_address ON properties (address COLLATE NOCASE)"
    execute "CREATE INDEX idx_contacts_on_info ON contacts (info COLLATE NOCASE)"
  end
  
  def down
    execute "DROP INDEX idx_properties_on_more_info"
    execute "DROP INDEX idx_properties_on_address"
    execute "DROP INDEX idx_contacts_on_info"
  end
end
