Rails.application.routes.draw do

  namespace :queue do
    #get '/', to: 'job#search', as: 'job_index'
    resources :job
  end

  devise_for :users, controllers: {omniauth_callbacks: 'users/omniauth'}

  root to: 'queue#index'
  get 's', to: 'instagram_user#search', as: 'search'
  get 'u/:id', to: 'instagram_user#profile', as: 'view_profile'
  post '/jobs/follow', to: 'job#follow', as: 'new_follow_job'
  post '/jobs/cancel', to: 'job#cancel', as: 'cancel_job'
  post '/jobs/remove', to: 'job#remove', as: 'remove_job'
  get '/limits', to: 'queue#limits', as: 'limits'
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq12345'

  #   get '/limits', to: 'sessions#view_instagram_api_limits'
  #   get '/playground', to: 'queue#playground'
end

# The priority is based upon order of creation: first created -> highest priority.
# See how all your routes lay out with "rake routes".

# You can have the root of your site routed with "root"
# root 'welcome#search'

# Example of regular route:
#   get 'products/:id' => 'catalog#view'

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
