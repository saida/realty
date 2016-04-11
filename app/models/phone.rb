class Phone < ActiveRecord::Base
  
  belongs_to :contact
  
  validates_presence_of :contact_id, :phone
  validates_uniqueness_of :phone, scope: :contact_id
end
