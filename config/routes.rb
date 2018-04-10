require 'sidekiq/web'
Rails.application.routes.draw do
  get 'welcome/index'

	mount Sidekiq::Web => '/sidekiq'

  mount WeixinRailsMiddleware::Engine, at: "/"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
