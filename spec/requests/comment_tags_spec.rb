require 'rails_helper'

RSpec.describe "CommentTags", type: :request do
  let(:user)      { create(:user) }
  let(:moderator) { create(:user, :recipe_moderator) }
  let(:recipe)    { create(:recipe) }
  let(:comment)   { create(:recipe_comment, recipe: recipe, user: user) }

  def tag_path(comment)
    tag_recipe_comment_path(comment)
  end

  # ---------------------------------------------------------------------------
  # POST /recipe_comments/:id/tag
  # ---------------------------------------------------------------------------
  describe "POST /recipe_comments/:id/tag" do
    context "as moderator" do
      before { sign_in moderator }

      it "adds an allowed tag and returns the updated tag list" do
        post tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["tags"]).to include("Markenempfehlung")
        expect(comment.reload.comment_type_list).to include("Markenempfehlung")
      end

      it "adds multiple allowed tags without duplicates" do
        post tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json
        post tag_path(comment), params: { tag: "Zubereitungstipp" }, as: :json
        post tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json  # duplicate

        json = JSON.parse(response.body)
        expect(json["tags"].count("Markenempfehlung")).to eq(1)
        expect(json["tags"]).to include("Zubereitungstipp")
      end

      it "rejects an unknown tag" do
        post tag_path(comment), params: { tag: "SomeRandomTag" }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
        expect(comment.reload.comment_type_list).to be_empty
      end

      it "rejects a blank tag" do
        post tag_path(comment), params: { tag: "" }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "accepts all allowed tags" do
        %w[Markenempfehlung Zubereitungstipp Zutatenvariante Erfahrungsbericht].each_with_index do |tag, i|
          c = create(:recipe_comment, recipe: recipe, user: user)
          post tag_recipe_comment_path(c), params: { tag: tag }, as: :json
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "as regular user" do
      before { sign_in user }

      it "returns 403 forbidden" do
        post tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
        expect(comment.reload.comment_type_list).to be_empty
      end
    end

    context "when not logged in" do
      it "returns 403 forbidden" do
        post tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /recipe_comments/:id/tag
  # ---------------------------------------------------------------------------
  describe "DELETE /recipe_comments/:id/tag" do
    before do
      comment.comment_type_list = [ "Markenempfehlung", "Zubereitungstipp" ]
      comment.save!
    end

    context "as moderator" do
      before { sign_in moderator }

      it "removes the specified tag and returns the updated list" do
        delete tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["tags"]).not_to include("Markenempfehlung")
        expect(json["tags"]).to include("Zubereitungstipp")
        expect(comment.reload.comment_type_list).not_to include("Markenempfehlung")
      end

      it "is a no-op when the tag is not present" do
        delete tag_path(comment), params: { tag: "Zutatenvariante" }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["tags"].sort).to eq([ "Markenempfehlung", "Zubereitungstipp" ].sort)
      end

      it "results in an empty list after removing all tags" do
        delete tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json
        delete tag_path(comment), params: { tag: "Zubereitungstipp" }, as: :json

        json = JSON.parse(response.body)
        expect(json["tags"]).to eq([])
      end
    end

    context "as regular user" do
      before { sign_in user }

      it "returns 403 forbidden" do
        delete tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(comment.reload.comment_type_list).to include("Markenempfehlung")
      end
    end

    context "when not logged in" do
      it "returns 403 forbidden" do
        delete tag_path(comment), params: { tag: "Markenempfehlung" }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # admin user also has moderator access
  # ---------------------------------------------------------------------------
  describe "admin access" do
    let(:admin) { create(:user, :admin) }
    before { sign_in admin }

    it "can add a tag" do
      post tag_path(comment), params: { tag: "Erfahrungsbericht" }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "can remove a tag" do
      comment.comment_type_list = [ "Erfahrungsbericht" ]
      comment.save!

      delete tag_path(comment), params: { tag: "Erfahrungsbericht" }, as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
