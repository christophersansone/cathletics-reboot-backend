Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end

  namespace :api do
    namespace :v1 do
      resource :signup, only: [:create], controller: "signup"
      resource :me, only: [:show, :update], controller: "me"
      resource :dashboard, only: [:show], controller: "dashboard"

      resources :users
      resources :organization_memberships, only: [:index]
      resources :seasons
      resources :leagues

      resources :activity_types do
        resources :seasons do
          resources :leagues
        end
      end
      resources :families do
        resources :family_memberships, path: "memberships"
        resources :children, only: [:create]
      end
      resources :family_memberships
      resources :children, only: [:create]

      resources :organizations, param: :slug do
        post :join, on: :member
        resources :organization_memberships, path: "memberships"
        resources :activity_types do
          resources :seasons do
            resources :leagues
          end
        end
      end

      resources :teams
      resources :registrations
      resources :team_memberships

      resources :leagues, only: [] do
        resources :teams
        resources :registrations
      end

      resources :teams, only: [] do
        resources :team_memberships, path: "memberships"
      end
    end
  end
end
