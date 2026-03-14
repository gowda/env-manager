Rails.application.routes.draw do
  resources :apps do
    resources :app_envs do
      resources :env_configs do
        resources :environment_variables
        resources :workflow_definitions, except: [:show]
        resources :workflow_runs, only: [:index, :show]
        resource :batch_changes, only: [:new, :create], controller: "env_config_batch_changes"
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "apps#index"
end
