class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception
  
  rescue_from ActiveRecord::RecordNotFound, with: :render_missing
  
  before_filter :authenticate_user!
  before_filter :identify_allowed_properties

  def identify_allowed_properties
    if current_user
      @user_properties_list = Rails.cache.read("all-properties-#{current_user.id}")
      unless @user_properties_list
        @user_properties_list = current_user.properties.map{ |p| p.id }.join(',')
        Rails.cache.write("all-properties-#{current_user.id}", @user_properties_list)
      end
    end
  end
  
  def properties_list
    @user_properties_list
  end
  
  def render_missing
    render text: "<div class=\"col-md-12\"><h2>Страница не найдена!</h2><br/><p>Такая страница не существует. Возможно, вы ошиблись в наборе ссылки или забыли пройти авторизацию.</p><p>Вы всегда можете вернуться на <a href=\"/\">главную страницу</a>.</p></div>", status: 404, layout: "application"
  end
end
