require 'stringio'
require 'socket'

module ApplicationHelper
  def main_menu
    if current_user.is_main
      [
        {title: 'Главная',      icon: 'home',   url: '/', controller: 'properties'},
        {title: "Категории",    icon: "bars",   url: categories_path, controller: 'categories', 
          children: [{ title: 'Варианты', controller: 'category_items' }]
        },
        {title: "Контакты",     icon: "phone", url: contacts_path,   controller: 'contacts'},
        {title: "Пользователи", icon: "users",  url: users_path,      controller: 'users'}
      ]
    else
      [
        {title: 'Главная',      icon: 'home',   url: '/', controller: 'properties'},
        {title: "Контакты",     icon: "phone", url: contacts_path,   controller: 'contacts'}
      ]
    end
  end

  def create_default_user
    if User.count == 0
      User.create!(username: 'admin', email: 'admin@admin.com', password: '12345678', password_confirmation: '12345678')
    end
  end
  
  def menu_builder
    attributes = {}
    menu = main_menu
    result = StringIO.new

    bread_crumbs = []
    named_routes = {}

    update = lambda do |items|
      active = false
      items.each do |item|
        is_active = (item[:url] && request.path == item[:url]) || \
          (item[:controller] && item[:controller] == controller_path) || \
          (item[:controllers] && item[:controllers].include?(controller_path))

        is_active||= update.call(item[:children]) if item[:children]
        active||= is_active
        klass = []
        klass << "first" if item == menu[0]
        klass << "active" if is_active
        attributes[item.hash] = {klass: klass.join(" ")}
        if is_active
          if item[:breadcrumb_append]
            bread_crumbs << item[:breadcrumb_append].call
          end
          bread_crumbs << item
          if item[:breadcrumb_prepend]
            bread_crumbs << item[:breadcrumb_prepend].call
          end
        end
      end
      active
    end
    update.call(menu)
    @bread_crumbs = bread_crumbs.reject{|c| !c.present?}.collect{|c| c.kind_of?(String) ? {title: c} : c}.reverse
    @title = @title || @bread_crumbs.collect {|i| i[:title]}.join(" : ")
    @page_title = @title
    if ['edit', 'new'].include?(params[:action])
      @page_title+= " - " + params[:action]
      @title = "#{h(@title)} <small><i class='fa-angle-right'></i> #{params[:action] == 'new' ? 'Новая запись' : 'Изменить запись' }</small>".html_safe
    end

    submenu = lambda do |items|
      items.each do |item|
        attrs = attributes[item.hash]
        children = !item[:url] && item[:children]
        next if children && children.length == 0

        result << "<li class='" << attrs[:klass] << "'>"
        result << "<a href='" << (children ? "javascript:;" : item[:url]) << "'>"
        result << " <i class='fa-" << item[:icon] << "'></i> " if item[:icon]
        result << "<span class='title'>" << h(item[:title]) << "</span>"
        result << "<span class='arrow#{attrs[:klass].include?('active') ? ' open' : ''}'></span>" if children
        result << "</a>"
        if children
          result << "<ul class='sub-menu'>"
          submenu.call(children)
          result << "</ul>"
        end
        result << "</li>"
      end
    end

    submenu.call(menu)
    result.string.html_safe
  end

  def breadcrumbs(homeurl = "/admin")
    result = StringIO.new
    result << "<li><i class='fa-home'></i>"
    result << "<i class='fa-angle-right'></i>" if @bread_crumbs.length > 0
    result << "</li>"

    @bread_crumbs.each do |item|
      result << "<li>"
      if item[:url]
        result << "<a href='" << item[:url] << "'>"
        result << h(item[:title])
        result << "</a>"
      else
        result << h(item[:title])
      end
      result << " <i class='fa-angle-right'></i> " if item != @bread_crumbs[-1]
      result << "</li>"
    end
    result.string.html_safe
  end
  
  def link_to_remove_fields(name, f, msg='Do you really want to delete this entry?')
    f.hidden_field(:_destroy) + link_to(name, "#", onclick: "var t=this; bootbox.confirm('#{msg}', function(r) {if(r) remove_fields(t)});return false")
  end
  
  def link_to_add_fields(name, f, association, path='', locals={}, options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(path + association.to_s.singularize + "_fields", locals.merge!(:f => builder))
    end
    link_to(name, "#", {onclick: "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\");return false;"}.merge(options))
  end
  
  def read_filter(idx)
    Rails.cache.fetch("#{session[:session_id]}-sSearch_#{idx}")
  end
  
  def entered_from_the_main_comp
    ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
    server_ip = ip.ip_address if ip
    server_ip && (request.remote_ip == server_ip || request.remote_ip == '127.0.0.1')
  end
end
