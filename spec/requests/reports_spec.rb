require 'rails_helper'

RSpec.describe "Reports", type: :request do
  let(:user) { create(:user) }
  let(:forum_post) { create(:forum_post) }

  describe "POST /reports" do
    context "when authenticated" do
      before { sign_in user }

      it "creates a new report with valid params" do
        expect {
          post reports_path, params: {
            report: {
              reportable_type: "ForumPost",
              reportable_id: forum_post.id,
              reason: "spam"
            }
          }, headers: { "Accept" => "application/json" }
        }.to change(Report, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end

      it "returns error for invalid reportable" do
        post reports_path, params: {
          report: {
            reportable_type: "User", # Not whitelisted
            reportable_id: user.id,
            reason: "spam"
          }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end

      it "returns error for missing description when reason is other" do
        post reports_path, params: {
          report: {
            reportable_type: "ForumPost",
            reportable_id: forum_post.id,
            reason: "other",
            description: ""
          }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post reports_path, params: {
          report: {
            reportable_type: "ForumPost",
            reportable_id: forum_post.id,
            reason: "spam"
          }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
