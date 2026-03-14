require "rails_helper"

RSpec.describe "Legacy cutover", type: :request do
  it "does not expose legacy variables routes" do
    get "/variables"

    expect(response).to have_http_status(:not_found)
  end
end
