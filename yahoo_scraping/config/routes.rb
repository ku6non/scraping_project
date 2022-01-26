Rails.application.routes.draw do
  root "auctions#index"

  resources :auctions
end
