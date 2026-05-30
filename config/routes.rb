Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  devise_for :users, path: "auth"

  get "users/me", to: "users#me", as: :me
  resources :users
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
  resource :profile, only: %i[edit update]
end
