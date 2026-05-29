require "rails_helper"

# TEMP_WIKI_PROD_HIDE: Remove this spec with the temporary production wiki gate.
RSpec.describe "Wiki production visibility", type: :request do
  let!(:article) { create(:wiki_article, title: "Gin Guide", body: "Everything about gin.", published: true) }

  def stub_rails_env(name)
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(name))
  end

  context "in production" do
    before { stub_rails_env("production") }

    it "returns 404 for guests" do
      get wiki_dashboard_path

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for regular users" do
      sign_in(create(:user))

      get wiki_article_path(article)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for guest edit routes before authentication redirects" do
      get new_wiki_article_path

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for JSON search" do
      get search_wiki_articles_path(format: :json, q: "Gin")

      expect(response).to have_http_status(:not_found)
    end

    it "allows wiki editors" do
      sign_in(create(:user, :wiki_editor))

      get wiki_dashboard_path

      expect(response).to have_http_status(:success)
    end
  end

  context "outside production" do
    it "keeps the wiki visible to guests on beta" do
      stub_rails_env("beta")

      get wiki_dashboard_path

      expect(response).to have_http_status(:success)
    end

    it "keeps the wiki visible to guests in development" do
      stub_rails_env("development")

      get wiki_dashboard_path

      expect(response).to have_http_status(:success)
    end
  end
end
