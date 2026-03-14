Rails.application.routes.draw do
  resources :apps do
    resources :app_envs, path: "app-envs" do
      resources :env_configs, path: "env-configs" do
        resources :environment_variables, path: "environment-variables"
        resources :workflow_definitions, path: "workflow-definitions", except: [:show]
        resources :workflow_runs, path: "workflow-runs", only: [:index, :show]
        resource :batch_changes, path: "batch-changes", only: [:new, :create], controller: "env_config_batch_changes"
      end
    end
  end

  scope "/apps/:app_id/app-envs/:app_env_id/env-configs/:env_config_id", as: nil do
    resources :environment_variables, path: "variables", controller: "environment_variables"
    resources :workflow_definitions, path: "workflows", controller: "workflow_definitions", except: [:show]
    resources :workflow_runs, path: "runs", controller: "workflow_runs", only: [:index, :show]
    resource :batch_changes, path: "batches", controller: "env_config_batch_changes", only: [:new, :create]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "apps#index"
end
