#!/usr/bin/env ruby
#coding: utf-8

class PropertiesController < ApplicationController  
  resources Property,
    datatables: {
      collection: :collection,
      fields: -> (row, res, klass) {[
        row.id,
        [row.price1, row.price2, row.price3],
        [row.rooms, row.floor, row.floors],
        row.address,
        row.more_info,
        row.images.count, # map{ |i| i.image? ? i.image_url : nil }.reject(&:blank?),
        row.state,
        row.contact_info,
        (row.clear_date? ? row.clear_date.strftime('%d.%m.%Y') + (row.clear_date >= Date.today && row.clear_date - 1.month <= Date.today ? '<br/><span class="label label-success">освобождается</span>' : '') : nil),
        (row.request_date? ? row.request_date.strftime('%d.%m.%Y') : nil),
        (row.last_call_date? ? row.last_call_date.strftime('%d.%m.%Y') : nil),
        row.viewed,
        row.price1, row.price2, row.price3, row.contact_id, row.contact_properties_count, '', '', '', '', '', '', '', '', '', ''
      ]}
    },
    notice: 'Запись успешно сохранена.'
  
  def collection(p)
    cond = []
    
    if params[:contact_id].present? && !params[:sSearch].present?
      cond << "contact_id = #{params[:contact_id]}"
    end
    # search by categories
    ([0] + (13..20).to_a).each do |i|
      item_ids = params["sSearch_#{i}"]
      if item_ids.present?
        cond << "properties.id IN (SELECT property_id FROM property_category_items pci WHERE pci.category_item_id IN (#{item_ids}))"
      end
    end
  
    if params[:sSearch_1].to_i == 1 # viewed
      cond << "viewed = 't'"
    end

=begin    
    if params[:sSearch_2].present? # address
      #address_q = []
      params[:sSearch_2].split(' ').each do |q|
        # join words by not AND but OR
        cond << "(address LIKE '%#{q}%' OR address LIKE '%#{q.mb_chars.capitalize.to_s}%')"
        # address_q << "(address LIKE '%#{q}%' OR address LIKE '%#{q.mb_chars.capitalize.to_s}%')"
      end
      #cond << "(" + address_q.join(' OR ') + ")"
      #address_q = nil
    end
    if params[:sSearch_3].present? # more_info
      #more_info_q = []
      params[:sSearch_3].split(' ').each do |q|
        # join words by not AND but OR
        cond << "(more_info LIKE '%#{q}%' OR more_info LIKE '%#{q.mb_chars.capitalize.to_s}%')"
        #more_info_q << "(more_info LIKE '%#{q}%' OR more_info LIKE '%#{q.mb_chars.capitalize.to_s}%')"
      end
      #cond << "(" + more_info_q.join(' OR ') + ")"
      #more_info_q = nil
    end
    if params[:sSearch_4].present? # contact
      contact_q = []
      params[:sSearch_4].split(' ').each do |q|
        # join words by not AND but OR
        # cond << "(contacts.info LIKE '%#{q}%' OR contacts.info LIKE '%#{q.mb_chars.capitalize.to_s}%')"
        contact_q << "(contacts.info LIKE '%#{q}%' OR contacts.info LIKE '%#{q.mb_chars.capitalize.to_s}%')"
      end
      cond << "(" + contact_q.join(' OR ') + ")"
      contact_q = nil
    end
=end

    if params[:sSearch_5].present? && params[:sSearch_6].present?
      from = params[:sSearch_5].to_i
      to = params[:sSearch_6].to_i
      cond << "((price1 is not null AND price1 >= #{from} AND price1 <= #{to}) OR (price2 is not null AND price2 >= #{from} AND price2 <= #{to}) OR (price3 is not null AND price3 >= #{from} AND price3 <= #{to}))"
    elsif params[:sSearch_5].present? # price from
      from = params[:sSearch_5].to_i
      cond << "((price1 is not null AND price1 >= #{from}) OR (price2 is not null AND price2 >= #{from}) OR (price3 is not null AND price3 >= #{from}))"
    elsif params[:sSearch_6].present? # price to
      to = params[:sSearch_6].to_i
      cond << "((price1 is not null AND price1 <= #{to}) OR (price2 is not null AND price2 <= #{to}) OR (price3 is not null AND price3 <= #{to}))"
    end
    if params[:sSearch_7].present? # last call date
      cond << "last_call_date >= date('#{Date.parse(params[:sSearch_7])}')"
    end
    if params[:sSearch_8].present?
      cond << "last_call_date <= date('#{Date.parse(params[:sSearch_8])}')"
    end
    if params[:sSearch_9].present? # request date
      cond << "request_date >= date('#{Date.parse(params[:sSearch_9])}')"
    end
    if params[:sSearch_10].present?
      cond << "request_date <= date('#{Date.parse(params[:sSearch_10])}')"
    end
    if params[:sSearch_11].present? # clear date
      cond << "clear_date >= date('#{Date.parse(params[:sSearch_11])}')"
    end
    if params[:sSearch_12].present?
      cond << "clear_date <= date('#{Date.parse(params[:sSearch_12])}')"
    end
    
    if params[:sSearch_21].present? && params[:sSearch_22].blank?
      cond << "images.id IS NOT NULL"
    elsif params[:sSearch_22].present? && params[:sSearch_21].blank?
      cond << "images.id IS NULL"
    end
    
    if params[:sSearch_23].present?
      contact_id = params[:sSearch_23]
      cond << "properties.id IN (SELECT pr.id
                                 FROM properties pr 
                                 WHERE pr.contact_id IN (SELECT DISTINCT(phones.contact_id)
                                                         FROM phones
                                                         WHERE phones.phone IN (SELECT phone
                                                                                FROM phones p
                                                                                WHERE p.contact_id = #{contact_id})))"
    end
    
    conditions = cond.join(' AND ')
    
    (0..26).each do |i|
      Rails.cache.write("#{session[:session_id]}-sSearch_#{i}", params["sSearch_#{i}"].to_s, overwrite: true)
    end
    
    p = p.joins("LEFT OUTER JOIN contacts ON contacts.id = properties.contact_id LEFT OUTER JOIN images ON images.property_id = properties.id")
         .where(conditions)
         .select(:price1, :rooms, :address, :more_info, :state, "contacts.info as 'contact_info'", :clear_date,
                  :request_date, :last_call_date, :viewed, :rental_date, :request_date,
                  :price2, :price3, :floor, :floors, "properties.id as 'id'").uniq
        
    unless current_user.is_main
      p = p.where("properties.id IN (#{ properties_list })").uniq
    end

    if params[:sSearch_2].present? # address
      params[:sSearch_2].split(' ').each do |q|
        p = p.select { |n| n.address.to_s.mb_chars.downcase.index(q.mb_chars.downcase) }
      end
    end
    if params[:sSearch_3].present? # more_info
      params[:sSearch_3].split(' ').each do |q|
        p = p.select { |n| n.more_info.to_s.mb_chars.downcase.index(q.mb_chars.downcase) }
      end
    end
    if params[:sSearch_4].present? # contact
      params[:sSearch_4].split(' ').each do |q|
        p = p.select { |n| n.contact_info.to_s.mb_chars.downcase.index(q.mb_chars.downcase) }
      end
    end


    p = Property.joins("LEFT OUTER JOIN contacts ON contacts.id = properties.contact_id LEFT OUTER JOIN images ON images.property_id = properties.id")
          .where(id: p.map(&:id))
          .select(:price1, :rooms, :address, :more_info, :state, "contacts.info as 'contact_info'", :clear_date,
                    :request_date, :last_call_date, :viewed, :rental_date, :request_date,
                    :price2, :price3, :floor, :floors, "properties.id as 'id'", :contact_id,
                    "(SELECT COUNT(DISTINCT(pr.id))
                      FROM properties pr
                      WHERE pr.contact_id IN (SELECT DISTINCT(phones.contact_id)
                                              FROM phones
                                              WHERE phones.phone IN (SELECT phone
                                                                     FROM phones p
                                                                     WHERE p.contact_id = properties.contact_id))) AS 'contact_properties_count'").uniq
                    
    p
  end
    
  def before_index
    @categories = Category.actives
    
    @district = @categories.select{ |c| c.un == 'district' }[0]
    @categories = @categories - [@district]
    @status = @categories.select{ |c| c.un == 'status' }[0]
  end
  
  def toggle_viewed
    @property = Property.find(params[:id])
    @property.viewed = params[:n] == 1 ? true : (params[:n] == 0 ? false : nil)
    @property.save!
    render nothing: true
  end
    
  def show_modal
    @property = Property.find(params[:id])
    @images = @property.images

    respond_to do |format|
      format.html { render partial: 'property' }
      format.js
    end
  end
  
  def update_statuses
    if params[:property_id].present?
      property_ids = params[:property_id].compact.join(',')
      
      category_items = Category.find_by_un('status').category_items
      all_items = category_items.pluck(:id).join(',')
      
      new_item = params[:status] == 'null' ? nil : category_items.find(params[:status])
      Property.transaction do
        Property.where("id IN (#{property_ids})").each do |property|
          property.property_category_items.where("category_item_id IN (#{all_items})").delete_all
          if new_item
            property.property_category_items.build(category_item_id: new_item.id)
            property.state = "<span class='label label-sm label-#{new_item.color}'>#{ new_item.name }</span>"
          else
            property.state = nil
          end
          property.last_call_date = Date.today
          property.save!
        end
      end
    end
    render nothing: true
  end

  def before_new
    @categories = @property.categories
    @contact = Contact.new
  end
  
  def before_edit
    @categories = @property.categories
    @contact = @property.contact || Contact.new
    @images = @property.images
    
    Category.actives.each do |category|
      unless @categories.include?(category)
        (category.un == 'service_type' ? 3 : 1).times {
          @property.property_category_items.build
        }
      end
    end
  end
    
  def after_save
    if params[:images] && params[:images][:image]
      params[:images][:image].each do |image|
        @params = {}
        @params['image'] = image
        @property.images.create(@params)
      end
    end
    
    if @property.contact_id?
      @property.contact.update_attributes(contact_params)
    else
      @property.contact = Contact.create!(contact_params)
      @property.save!
    end
  end
  
  def update_contact
    @contact = params[:contact_id].present? ? Contact.find(params[:contact_id]) : Contact.new
    
    respond_to do |format|
      format.js
    end
  end
  
  def contact_params
    if params[:contact]
      params.require(:contact).permit(:info)
    end
  end
  
  def delete_image
    @property = Property.find(params[:id])
    @image = @property.images.find(params[:image_id])
    @image.destroy
    
    respond_to do |format|
      format.html { redirect_to action: :edit, id: @property.id }
      format.js
    end
  end
  
  def sort_images
    @property = Property.find(params[:id])
    
    Property.transaction do
      @property.images.each do |image|
        weight = params[:image].index(image.id.to_s).to_i + 1
        image.update_attributes!(weight: weight) unless image.weight == weight
      end
    end
    
    render nothing: true
  end
  
  def move_images
    renamed = false
    properties = Property.includes(:images).select{ |p| (p.rooms.to_s[/\d+/].to_i > 9 || p.floor.to_s[/\d+/].to_i > 9 || p.floors.to_s[/\d+/].to_i > 9) && p.images.present? }
    
    properties.each do |property|
      district = Russian.translit(property.item(:district).force_encoding('utf-8'))
      landmark = Russian.translit(property.landmark.force_encoding('utf-8'))
      kee = "#{property.rooms.to_s[/\d+/]}-#{property.floor.to_s[/\d+/]}-#{property.floors.to_s[/\d+/]}"
      price = [property.price1, property.price2, property.price3].reject(&:blank?).join(' ')
      info = "#{kee} #{landmark} #{price}"
      new_path = Rails.root.join('public', 'photos', district, info)
      
      old_kee = "#{property.rooms.to_s.scan(/\d/)[0]}-#{property.floor.to_s.scan(/\d/)[0]}-#{property.floors.to_s.scan(/\d/)[0]}"
      old_info = "#{old_kee} #{landmark} #{price}"
      old_path = Rails.root.join('public', 'photos', district, old_info)
      
      if Dir.exists?(old_path)
        File.rename old_path, new_path
        renamed = true
      end
    end
    
    render text: renamed ? 'Cтарые картинки были перемещены' : 'Cтарые картинки не существуют', layout: false
  end
  
  def open_directory
    property = Property.find(params[:id])
    img = property.images.last
    isWindows = request.env['HTTP_USER_AGENT'].to_s.downcase.match(/windows/i)
    if isWindows
      system("explorer \"#{img.image.path.to_s.gsub(img.image_file_name, '').gsub(/\//, "\\")}\"")
    else
      system("open \"#{img.image.path.to_s.gsub(img.image_file_name, '')}\"")
    end
    render nothing: true
  end
end
