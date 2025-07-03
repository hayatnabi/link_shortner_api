Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      post 'shorten', to: 'links#create'
      get ':short_code', to: 'links#redirect', as: 'short_redirect'
      get ':short_code/stats', to: 'links#stats'
      get ':short_code/qr', to: 'links#qr_code'
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
