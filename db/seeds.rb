# ruby encoding: utf-8

require 'sqlite3'

def create_category(name, un, weight)
  category = Category.find_by_un(un)
  if !category
    puts "Seeding #{name}..." if name
    category = Category.create!(name: name, un: un, weight: weight)
  end
  category
end

create_category 'Район/Квартал',      'district',       1
create_category 'Тип сервиса',        'service_type',   2
create_category 'Материал постройки', 'material',       3
create_category 'Тип помещения',      'property_type',  4
create_category 'Количество комнат',  'rooms',          5
create_category 'Этаж',               'floor',          6
create_category 'Этажность',          'floors',         7
create_category 'Состояние ремонта',  'condition',      8
create_category 'Свободно / Сдано',   'status',         9

def import_old_db(db_path)
  db = SQLite3::Database.new db_path

  rows = db.execute <<-SQL
    SELECT services.name 'service', services2.name 'service 2', services3.name 'service 3', services4.name 'service 4',
           prices.name 'price', prices2.name 'price 2', prices3.name 'price 3',
           districts.name 'district', ptypes.name 'property type', rooms.name 'rooms', storey.name 'floor', stories.name 'floors',
           htypes.name 'material', rtypes.name 'room type', conditions.name 'condition', states.name 'status',
           is_visited 'visited', orientirsdescr 'landmark', furnituredescr 'more_info', contactdescr 'contact', 
           betdate 'request_date', freedate 'clear_date', lastcontacttalkdate 'last_call_date', rentadate 'rental_date'

    FROM rl_tbl_houses houses LEFT JOIN rl_tbl_servicetypes services  ON houses.ref_st_id1 = services.st_id
                              LEFT JOIN rl_tbl_servicetypes services2 ON houses.ref_st_id2 = services2.st_id
                              LEFT JOIN rl_tbl_servicetypes services3 ON houses.ref_st_id3 = services3.st_id
                              LEFT JOIN rl_tbl_servicetypes services4 ON houses.ref_st_id4 = services4.st_id
                              LEFT JOIN rl_tbl_pricelevels  prices    ON houses.ref_pl_id1 = prices.pl_id
                              LEFT JOIN rl_tbl_pricelevels  prices2   ON houses.ref_pl_id2 = prices2.pl_id
                              LEFT JOIN rl_tbl_pricelevels  prices3   ON houses.ref_pl_id3 = prices3.pl_id
                              LEFT JOIN rl_tbl_districts    districts ON houses.ref_d_id1 = districts.d_id
                              LEFT JOIN rl_tbl_accommodtypes ptypes   ON houses.ref_at_id = ptypes.at_id
                              LEFT JOIN rl_tbl_roomscounts  rooms     ON houses.ref_rc_id = rooms.rc_id
                              LEFT JOIN rl_tbl_stories      storey    ON houses.ref_s_id = storey.s_id
                              LEFT JOIN rl_tbl_storiescounts stories  ON houses.ref_sc_id = stories.sc_id
                              LEFT JOIN rl_tbl_housetypes   htypes    ON houses.ref_ht_id = htypes.ht_id
                              LEFT JOIN rl_tbl_roomtypes   rtypes     ON houses.ref_rt_id = rtypes.rt_id
                              LEFT JOIN rl_tbl_repairstates conditions ON houses.ref_rs_id = conditions.rs_id
                              LEFT JOIN rl_tbl_nowfreetypes states    ON houses.ref_nf_id = states.nf_id;
  SQL
  
  Contact.delete_all
  PropertyCategoryItem.delete_all
  Property.delete_all
  
  district = Category.find_by_un('district').id
  service_type = Category.find_by_un('service_type').id
  material = Category.find_by_un('material').id
  property_type = Category.find_by_un('property_type').id
  rooms = Category.find_by_un('rooms').id
  floor = Category.find_by_un('floor').id
  floors = Category.find_by_un('floors').id
  condition = Category.find_by_un('condition').id
  status = Category.find_by_un('status').id
  
  # 0. service,   1. service 2,   2. service 3,     3. service 4
  # 4. price,     5. price 2,     6. price 3,       7. district,    8. property type,
  # 9. rooms,     10. floor,      11. floors,       12. material,   13. room type,
  # 14. condition, 15. status,    16. visited,      17. landmark,   18. more_info,  19. contact,
  # 20. request_date,     21. clear_date,     22. last_call_date,   23. rental_date
  
  Property.transaction do
    rows.each_with_index do |row, i|
      contact = Contact.create!(info: row[19], properties_count: 1)
      property = Property.create!(
        contact_id: contact.id,
        price1: row[4].present? ? row[4].gsub(/-|\$|\$\s/, '').to_i : nil,
        price2: row[5].present? ? row[5].gsub(/-|\$|\$\s/, '').to_i : nil,
        price3: row[6].present? ? row[6].gsub(/-|\$|\$\s/, '').to_i : nil,
        landmark: row[17],
        more_info: row[18],
        request_date: row[20],
        clear_date: row[21],
        last_call_date: row[22],
        rental_date: row[23],
        address: [row[17], row[7]].compact.join(', '),
        rooms: row[9],
        floor: row[10],
        floors: row[11],
        state: "<span class='label label-sm label-default'>#{ row[15] }</span>"
      )
      p_id = property.id
      items = []
      items << CategoryItem.find_or_create_by_category_id_and_name!(district,     row[7])
      items << CategoryItem.find_or_create_by_category_id_and_name!(service_type, row[0])
      items << CategoryItem.find_or_create_by_category_id_and_name!(service_type, row[1])
      items << CategoryItem.find_or_create_by_category_id_and_name!(service_type, row[2])
      items << CategoryItem.find_or_create_by_category_id_and_name!(material,     row[12])
      items << CategoryItem.find_or_create_by_category_id_and_name!(property_type, row[8])
      items << CategoryItem.find_or_create_by_category_id_and_name!(rooms,        row[9])
      items << CategoryItem.find_or_create_by_category_id_and_name!(floor,        row[10])
      items << CategoryItem.find_or_create_by_category_id_and_name!(floors,       row[11])
      items << CategoryItem.find_or_create_by_category_id_and_name!(condition,    row[14])
      items << CategoryItem.find_or_create_by_category_id_and_name!(status,       row[15])
    
      items.each do |item|
        PropertyCategoryItem.create!(property_id: p_id, category_item_id: item.id)
      end
      puts "#{i}. #{property.price1}, #{property.price2}. #{row[7]}, #{row[17]}"
    end
  end
end

# import_old_db 'db/realty2'

def set_viewed(db_path)
  db = SQLite3::Database.new db_path

  rows = db.execute <<-SQL
    SELECT is_visited, orientirsdescr, contactdescr, rooms.name 'rooms', storey.name 'floor'
    FROM rl_tbl_houses houses LEFT JOIN rl_tbl_roomscounts  rooms   ON houses.ref_rc_id = rooms.rc_id
                              LEFT JOIN rl_tbl_stories      storey  ON houses.ref_s_id = storey.s_id
    WHERE is_visited != 0;
  SQL
  
  # 0. visited  1. landmark   2. contact  3. rooms  4. floor
  
  Property.transaction do
    rows.each do |row|
      properties = Property.joins(:contact).where("landmark = ? AND contacts.info = ? AND rooms = ? AND floor = ?", row[1], row[2], row[3], row[4])
      
      if properties.present?
        properties.where(viewed: false).update_all(viewed: row[0] == 1 ? true : nil)
        puts "#{ row[1] } | #{row[0]}"
      else
        puts "------------------ Не найдено: #{row[1]} | #{row[2]} | к/э #{row[3]}/#{row[4]}"
      end
    end
  end
  
  # one repeated property with different price and viewed
  properties = Property.joins(:contact).where("contacts.info like '%т.Мухаё%' AND price1 = 250")
  properties.update_all(viewed: true) if properties.present?
  
  puts "Done!"
end

set_viewed('db/realty2')