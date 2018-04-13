require 'sidekiq/web'
Rails.application.routes.draw do
  resources :posts do
  	member do
  		post 'favs'
  	end
  	collection do
  		post 'fav'
  	end
  end
  resources :users
  get 'welcome/index'

	mount Sidekiq::Web => '/sidekiq'

  mount WeixinRailsMiddleware::Engine, at: "/"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end