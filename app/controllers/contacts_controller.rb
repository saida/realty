class ContactsController < ApplicationController
  resources Contact,
    datatables: {
      search: [:info],
      collection: :collection,
      fields: -> (row, res, klass) {[ row.info, row.properties_count ]}
    },
    notice: 'Контакт успешно сохранен.'
  
  def collection(c)
    c = c.select(:info, :properties_count)
    
    unless current_user.is_main
      c = c.where("id IN (SELECT c.id FROM contacts c INNER JOIN properties p ON c.id = p.contact_id WHERE p.id IN (#{ properties_list }))").uniq
    end
    c
  end
  
  def search
    q = params[:q]
    @contacts = Contact.where("info like '%#{q}%' OR info LIKE '%#{q.mb_chars.capitalize.to_s}%'")
    render json: @contacts
  end
  
  # empty the session cache
  def after_save
    cookies['global_properties_for_user'] = nil
  end
end
