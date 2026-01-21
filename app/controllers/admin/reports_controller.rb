module Admin
  class ReportsController < BaseController
    def count
      render json: { count: Report.pending.count }
    end

    def index
      @filter = params[:filter] || "pending"
      @reports = Report.includes(:reporter, :reportable)
                       .order(created_at: :desc)

      if @filter == "pending"
        @reports = @reports.where(status: :pending)
      else
        @reports = @reports.where.not(status: :pending)
      end

      @pagy, @reports = pagy(@reports)
    end

    def update
      @report = Report.find(params[:id])

      case params[:status]
      when "resolved"
        @report.resolved!
        @report.update(resolved_by: Current.user, resolution_notes: params[:resolution_notes])
        flash[:notice] = "Meldung als gelöst markiert."
      when "dismissed"
        @report.dismissed!
        @report.update(resolved_by: Current.user, resolution_notes: params[:resolution_notes])
        flash[:notice] = "Meldung abgelehnt."
      end

      redirect_to admin_reports_path(filter: "pending")
    end
  end
end
