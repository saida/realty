class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception
  
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
end
