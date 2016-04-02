Realty::Application.routes.draw do
  
  root to: 'properties#index'
  get "/move",    to: 'properties#move_images'
  
  def properties_resources
    resources :properties do
      member do
        get :show_modal, :toggle_viewed, :delete_image, :open_directory
        post :sort_images
      end
      collection do
        post :update_contact, :update_statuses
        put :index
      end
    end
  end
  
  properties_resources
  
  resources :contacts do
    collection do
      post :search
    end
    properties_resources
  end

  resources :users
  
  resources :categories do
    resources :category_items, as: :items, path: 'items'
  end
  
  mount Ckeditor::Engine => '/ckeditor'
  devise_for :users, path: "/", path_names: {sign_in: 'login', sign_out: 'logout'}
  match "*nodes_path", to: "application#render_missing", via: [:get, :post]
end