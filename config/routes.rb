Rails.application.routes.draw do
  resources :variables

  resources :apps do
    resources :app_envs do
      resources :env_configs do
        resources :environment_variables
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "apps#index"
end
