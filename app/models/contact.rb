class Contact < ActiveRecord::Base
  
  has_many :properties
  has_many :phones, dependent: :destroy
  
  scope :actives, -> { order(:info) }
  
  after_save :update_properties_count
  after_save :update_phones
  
  def self.selectables
    actives.collect{ |c| [c.info, c.id] }
  end
  
  def self.of_user(user)
    select(:info, "count(distinct properties.id) as 'p_count'")
      .joins(:properties).group("contacts.id")
      .where(user.is_main ? '' : ["properties.id IN (#{user.properties_list})"])
  end
  
  def after_save
    update_attributes!(properties_count: properties.size)
  end
  
  def update_properties_count
    properties_count = properties.size
  end
  
  def self.update_properties_count # takes a long time
    contacts = Contact.select("contacts.id, count(*) as 'p_count'").joins(:properties).group('contacts.id')
    contacts.each { |c| Contact.where(id: c.id).update_all(properties_count: c.p_count) }
  end
  
  def update_phones
    contact = self
    contact.phones.each { |p| p.destroy }
    
    phones = (contact.info || '').split(/\s/).map { |word|
      if word.length >= 7
        n = word.scan(/\d/).join('')
        if n.length >= 7
          n
        end
      end
    }.reject(&:blank?)
    
    if phones.present?
      puts "Adding phones for #{contact.info}"
      Phone.transaction do
        phones.each do |phone|
          contact.phones.find_or_create_by(phone: phone)
        end
      end
    end
  end
end
