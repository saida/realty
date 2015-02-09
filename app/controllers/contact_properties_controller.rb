class ContactPropertiesController < ApplicationController
  resources Property,
    belongs_to: Contact,
    datatables: {
      collection: :collection,
      search: [ :landmark, :more_info ],
      fields: -> (row) {[
        (row.request_date? ? Russian.strftime(row.request_date, '%d %B %Y') : nil),
        (row.last_call_date? ? Russian.strftime(row.last_call_date, '%d %B %Y') : nil), 
        (row.clear_date? ? Russian.strftime(row.clear_date, '%d %B %Y') : nil),
        (row.rental_date? ? Russian.strftime(row.rental_date, '%d %B %Y') : nil),
        (row.landmark.to_s + ', ' + row.item(:district).to_s)
      ]}
    },
    notice: 'Запись успешно сохранена.'

  def collection(p)
    if params[:contact_id] && !params[:sSearch].present?
      p = p.where(contact_id: params[:contact_id])
    end
    p.select(:request_date, :last_call_date, :clear_date, :rental_date, :landmark, :contact_id)
  end
end
