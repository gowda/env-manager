require "rails_helper"

RSpec.describe "Apps", type: :request do
  describe "GET /apps" do
    it "returns a successful response" do
      get apps_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="/assets/application))
      expect(response.body).to include(%(src="/assets/application))
    end
  end

  describe "POST /apps" do
    it "creates an app" do
      expect do
        post apps_path, params: {
          app: {
            name: "Payments",
            description: "Payments service",
            github_repository: "org/payments",
            url: "https://payments.example.com"
          }
        }
      end.to change(App, :count).by(1)

      expect(response).to redirect_to(app_path(App.last))
    end
  end
end
