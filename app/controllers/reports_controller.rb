class ReportsController < ApplicationController
  def create
    @report = Report.new(report_params)
    @report.reporter = Current.user

    # Ensure reportable exists and is valid
    unless valid_reportable?
      return render json: { success: false, error: "Ungültiger Inhalt" }, status: :unprocessable_content
    end

    if @report.save
      render json: { success: true, message: "Danke für deine Meldung! Wir werden uns darum kümmern." }
    else
      render json: { success: false, errors: @report.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def report_params
    params.require(:report).permit(:reportable_type, :reportable_id, :reason, :description)
  end

  def valid_reportable?
    # Whitelist allowed classes
    allowed_classes = [ "ForumPost", "RecipeComment", "PrivateMessage" ]
    return false unless allowed_classes.include?(@report.reportable_type)

    # Check existence
    @report.reportable.present?
  end
end
