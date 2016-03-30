Rails.application.routes.draw do
  mount Soulmate::Server, at: '/soulmate'

  get '/flickr_images/:festival' => 'festivals#flickr_images'
  get '/festival-list' => 'festivals#festival_list'

  post '/festival-select' => 'festivals#festival_select'
  post '/usr-info' => 'festivals#get_usr_info'
  post '/festival-unselect' => 'festivals#festival_unselect'

  root 'festivals#all'

  get '/festivals' => 'festivals#parse_all'

  resources :festivals, only: [:show] do
   get :autocomplete_airport_name, :on => :collection
 end
  
  get '/search_flights' => 'festivals#search_flights', defaults: { format: 'js' }

  get '/search_greyhound' => 'festivals#search_greyhound', defaults: { format: 'js' }

  get 'autocomplete', to: 'festivals#autocomplete', defaults: {format: 'json'}

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
     #get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
