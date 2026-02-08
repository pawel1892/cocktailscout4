require 'rails_helper'

RSpec.describe "Admin::Reports", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:moderator) { create(:user, :forum_moderator) }
  let(:super_mod) { create(:user, :super_moderator) }
  let(:user) { create(:user) }
  let!(:report) { create(:report) }

  describe "GET /admin/reports" do
    context "as admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_reports_path
        expect(response).to have_http_status(:success)
      end

      it "filters by status" do
        resolved_report = create(:report, status: :resolved, description: "Resolved Report Unique Text")
        get admin_reports_path, params: { filter: "all" }
        expect(response.body).to include("Resolved Report Unique Text")
      end
    end

    context "as moderator" do
      before { sign_in moderator }

      it "returns http success" do
        get admin_reports_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as super moderator" do
      before { sign_in super_mod }

      it "returns http success" do
        get admin_reports_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as regular user" do
      before { sign_in user }

      it "redirects to root" do
        get admin_reports_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end
  end

  describe "PATCH /admin/reports/:id" do
    context "as moderator" do
      before { sign_in moderator }

      it "resolves a report" do
        patch admin_report_path(report), params: { status: "resolved", resolution_notes: "Fixed" }
        report.reload
        expect(report.resolved?).to be true
        expect(report.resolved_by).to eq(moderator)
        expect(report.resolution_notes).to eq("Fixed")
        expect(response).to redirect_to(admin_reports_path(filter: "pending"))
      end

      it "dismisses a report" do
        patch admin_report_path(report), params: { status: "dismissed", resolution_notes: "Ignored" }
        report.reload
        expect(report.dismissed?).to be true
        expect(report.resolved_by).to eq(moderator)
        expect(response).to redirect_to(admin_reports_path(filter: "pending"))
      end
    end

    context "as super moderator" do
      before { sign_in super_mod }

      it "resolves a report" do
        patch admin_report_path(report), params: { status: "resolved", resolution_notes: "Fixed by super mod" }
        report.reload
        expect(report.resolved?).to be true
        expect(report.resolved_by).to eq(super_mod)
        expect(report.resolution_notes).to eq("Fixed by super mod")
        expect(response).to redirect_to(admin_reports_path(filter: "pending"))
      end
    end
  end

  describe "GET /admin/reports/count" do
    context "as moderator" do
      before { sign_in moderator }

      it "returns pending report count" do
        create_list(:report, 2, status: :pending)
        create(:report, status: :resolved)

        get count_admin_reports_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(3) # 1 from let! + 2 new pending
      end
    end

    context "as super moderator" do
      before { sign_in super_mod }

      it "returns pending report count" do
        create_list(:report, 2, status: :pending)
        create(:report, status: :resolved)

        get count_admin_reports_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(3) # 1 from let! + 2 new pending
      end
    end
  end
end
