require "rails_helper"

RSpec.describe "Admin::Units", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:recipe_moderator) { create(:user, :recipe_moderator) }
  let(:regular_user) { create(:user) }

  describe "Authorization" do
    context "as a regular user" do
      before { sign_in regular_user }

      it "redirects to root path" do
        get admin_units_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end

    context "as an admin" do
      before { sign_in admin }

      it "allows access to index" do
        get admin_units_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as a recipe moderator" do
      before { sign_in recipe_moderator }

      it "allows access to index" do
        get admin_units_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /admin/units" do
    before { sign_in admin }

    let!(:cl_unit) { create(:unit, name: "cl", display_name: "cl", category: "volume") }
    let!(:piece_unit) { create(:unit, name: "piece", display_name: "Stück", category: "count", ml_ratio: nil) }
    let!(:spritzer_unit) { create(:unit, :spritzer) }
    let!(:ingredient) { create(:ingredient) }
    let!(:recipe) { create(:recipe) }

    before do
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: cl_unit)
    end

    it "lists all units" do
      get admin_units_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("cl")
      expect(response.body).to include("Stück")
      expect(response.body).to include("Spritzer")
    end

    it "shows usage count" do
      get admin_units_path
      expect(response.body).to include("1") # cl_unit has 1 usage
    end

    context "filtering by usage" do
      it "filters by used units" do
        get admin_units_path, params: { usage: "used" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("cl")
        expect(response.body).not_to include("Stück")
      end

      it "filters by unused units" do
        get admin_units_path, params: { usage: "unused" }
        expect(response).to have_http_status(:success)
        # Check that piece_unit is shown but cl_unit is not in the table
        expect(response.body).to include("piece") # unit name
        expect(response.body).to include("Stück")
      end
    end

    context "filtering by category" do
      it "filters by volume category" do
        get admin_units_path, params: { category: "volume" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("cl")
        expect(response.body).not_to include("Stück")
      end

      it "filters by count category" do
        get admin_units_path, params: { category: "count" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("piece") # unit name
        expect(response.body).to include("Stück")
      end

      it "filters by special category" do
        get admin_units_path, params: { category: "special" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("spritzer") # unit name
        expect(response.body).to include("Spritzer")
      end
    end

    context "searching by name" do
      it "searches by name" do
        get admin_units_path, params: { q: "cl" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("cl")
        expect(response.body).not_to include("Stück")
      end

      it "searches by display_name" do
        get admin_units_path, params: { q: "Stück" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("piece") # unit name
        expect(response.body).to include("Stück")
      end
    end

    context "sorting" do
      it "sorts by name ascending" do
        get admin_units_path, params: { sort: "name", direction: "asc" }
        expect(response).to have_http_status(:success)
      end

      it "sorts by name descending" do
        get admin_units_path, params: { sort: "name", direction: "desc" }
        expect(response).to have_http_status(:success)
      end

      it "sorts by usage_count ascending" do
        get admin_units_path, params: { sort: "usage_count", direction: "asc" }
        expect(response).to have_http_status(:success)
      end

      it "sorts by usage_count descending" do
        get admin_units_path, params: { sort: "usage_count", direction: "desc" }
        expect(response).to have_http_status(:success)
      end

      it "sorts by category" do
        get admin_units_path, params: { sort: "category", direction: "asc" }
        expect(response).to have_http_status(:success)
      end

      it "sorts by created_at" do
        get admin_units_path, params: { sort: "created_at", direction: "desc" }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /admin/units/new" do
    before { sign_in admin }

    it "renders the new form" do
      get new_admin_unit_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Neue Einheit erstellen")
    end
  end

  describe "POST /admin/units" do
    before { sign_in admin }

    context "with valid params" do
      let(:valid_params) do
        {
          unit: {
            name: "oz",
            display_name: "oz",
            plural_name: "oz",
            category: "volume",
            ml_ratio: 29.57,
            divisible: true
          }
        }
      end

      it "creates a new unit" do
        expect {
          post admin_units_path, params: valid_params
        }.to change(Unit, :count).by(1)
      end

      it "redirects to index with success message" do
        post admin_units_path, params: valid_params
        expect(response).to redirect_to(admin_units_path)
        expect(flash[:notice]).to eq("Einheit wurde erfolgreich erstellt.")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          unit: {
            name: "",
            display_name: "oz",
            category: "volume"
          }
        }
      end

      it "does not create a unit" do
        expect {
          post admin_units_path, params: invalid_params
        }.not_to change(Unit, :count)
      end

      it "renders the new form with errors" do
        post admin_units_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Fehler")
      end
    end
  end

  describe "GET /admin/units/:id/edit" do
    before { sign_in admin }

    let(:unit) { create(:unit) }

    it "renders the edit form" do
      get edit_admin_unit_path(unit)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Einheit bearbeiten")
      expect(response.body).to include(unit.display_name)
    end

    context "when unit is used" do
      let!(:ingredient) { create(:ingredient) }
      let!(:recipe) { create(:recipe) }
      let!(:recipe_ingredient) { create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: unit) }

      it "shows usage warning" do
        get edit_admin_unit_path(unit)
        expect(response.body).to include("bg-yellow-50") # Yellow warning box
        expect(response.body).to include("Diese Einheit wird in")
        expect(response.body).to include("verwendet")
        expect(response.body).not_to include("Gefahrenzone") # Delete button should not be shown
      end
    end

    context "when unit is not used" do
      it "shows delete button in danger zone" do
        get edit_admin_unit_path(unit)
        expect(response.body).to include("Gefahrenzone")
        expect(response.body).to include("Einheit löschen")
      end
    end
  end

  describe "PATCH /admin/units/:id" do
    before { sign_in admin }

    let(:unit) { create(:unit, display_name: "cl") }

    context "with valid params" do
      let(:valid_params) do
        {
          unit: {
            display_name: "Centiliter",
            plural_name: "Centiliter"
          }
        }
      end

      it "updates the unit" do
        patch admin_unit_path(unit), params: valid_params
        unit.reload
        expect(unit.display_name).to eq("Centiliter")
      end

      it "redirects to index with success message" do
        patch admin_unit_path(unit), params: valid_params
        expect(response).to redirect_to(admin_units_path)
        expect(flash[:notice]).to eq("Einheit wurde erfolgreich aktualisiert.")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          unit: {
            display_name: "",
            category: "volume"
          }
        }
      end

      it "does not update the unit" do
        original_display_name = unit.display_name
        patch admin_unit_path(unit), params: invalid_params
        unit.reload
        expect(unit.display_name).to eq(original_display_name)
      end

      it "renders the edit form with errors" do
        patch admin_unit_path(unit), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Fehler")
      end
    end
  end

  describe "DELETE /admin/units/:id" do
    before { sign_in admin }

    context "when unit is not used" do
      let(:unit) { create(:unit) }

      it "deletes the unit" do
        unit # create the unit first
        expect {
          delete admin_unit_path(unit)
        }.to change(Unit, :count).by(-1)
      end

      it "redirects to index with success message" do
        delete admin_unit_path(unit)
        expect(response).to redirect_to(admin_units_path)
        expect(flash[:notice]).to eq("Einheit wurde erfolgreich gelöscht.")
      end
    end

    context "when unit is used in recipe ingredients" do
      let(:unit) { create(:unit) }
      let(:ingredient) { create(:ingredient) }
      let(:recipe) { create(:recipe) }

      before do
        create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, unit: unit)
      end

      it "does not delete the unit" do
        unit # create the unit first
        expect {
          delete admin_unit_path(unit)
        }.not_to change(Unit, :count)
      end

      it "redirects to index with error message" do
        delete admin_unit_path(unit)
        expect(response).to redirect_to(admin_units_path)
        expect(flash[:alert]).to include("Einheit kann nicht gelöscht werden")
        expect(flash[:alert]).to include("Rezeptzutat(en)")
      end
    end
  end
end
