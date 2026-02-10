class UnitsController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    @units = Unit.order(:category, :name)
    render json: {
      units: @units.map do |u|
        {
          id: u.id,
          name: u.name,
          display_name: u.display_name,
          plural_name: u.plural_name,
          category: u.category,
          divisible: u.divisible
        }
      end
    }
  end
end
