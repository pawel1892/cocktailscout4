require 'rails_helper'

RSpec.describe "Home Page", type: :request do
  describe "GET /" do
    it "renders the landing page with key features" do
      get root_path
      expect(response).to have_http_status(:success)

      # Welcome Section
      expect(response.body).to include("Willkommen bei CocktailScout")
      expect(response.body).to include("Entdecke die Welt der Cocktails")

      # Meine Bar Feature
      expect(response.body).to include("Meine Bar")
      expect(response.body).to include("Sag uns, welche Zutaten du zu Hause hast")
      expect(response.body).to include(my_bar_path)

      # Other Features
      expect(response.body).to include("Community")
      expect(response.body).to include(forum_topics_path)

      expect(response.body).to include("Rezepte")
      expect(response.body).to include(recipes_path)

      expect(response.body).to include("Galerie")
      expect(response.body).to include(recipe_images_path)

      # Meta Tags
      expect(response.body).to include('Cocktail-Rezepte, Drinks')
      expect(response.body).to include('name="description" content="Willkommen bei CocktailScout.de')
    end

    it "includes the activity stream script tag" do
      get root_path
      expect(response.body).to include("window.activityStream")
    end

    it "mounts the compact activity-stream component" do
      get root_path
      expect(response.body).to include("activity-stream compact")
    end

    it "populates the activity stream with recent events" do
      recipe = create(:recipe)
      get root_path
      expect(response.body).to include(recipe.slug)
    end

    describe "news threads section" do
      context "when the news forum exists with threads" do
        let!(:news_topic) { create(:forum_topic, slug: ForumTopic::NEWS_FORUM_SLUG) }
        let!(:oldest) { create(:forum_thread, forum_topic: news_topic, title: "Old News", created_at: 3.days.ago) }
        let!(:middle) { create(:forum_thread, forum_topic: news_topic, title: "Mid News", created_at: 2.days.ago) }
        let!(:newest) { create(:forum_thread, forum_topic: news_topic, title: "New News", created_at: 1.day.ago) }
        let!(:fourth) { create(:forum_thread, forum_topic: news_topic, title: "Even Older", created_at: 4.days.ago) }

        it "shows the Neuigkeiten section" do
          get root_path
          expect(response.body).to include("Neuigkeiten")
        end

        it "shows the three most recent threads" do
          get root_path
          expect(response.body).to include("New News")
          expect(response.body).to include("Mid News")
          expect(response.body).to include("Old News")
        end

        it "does not show the fourth thread" do
          get root_path
          expect(response.body).not_to include("Even Older")
        end

        it "shows thread dates" do
          get root_path
          expect(response.body).to include(newest.created_at.strftime("%d.%m.%Y"))
        end

        it "links to each thread" do
          get root_path
          expect(response.body).to include(forum_thread_path(newest))
        end
      end

      context "when the news forum does not exist" do
        it "does not show the Neuigkeiten section" do
          get root_path
          expect(response.body).not_to include("Neuigkeiten")
        end
      end

      context "when the news forum exists but has no threads" do
        before { create(:forum_topic, slug: ForumTopic::NEWS_FORUM_SLUG) }

        it "does not show the Neuigkeiten section" do
          get root_path
          expect(response.body).not_to include("Neuigkeiten")
        end
      end
    end

    describe "featured image" do
      let(:uploader)  { create(:user) }
      let(:moderator) { create(:user) }
      let(:recipe)    { create(:recipe, user: uploader, is_public: true) }

      def create_featured_image(recipe: nil)
        target = recipe || self.recipe
        ri = RecipeImage.new(
          recipe: target, user: uploader,
          state: "approved", moderated_at: Time.current, moderated_by: moderator,
          featured_at: Time.current
        )
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg')
        ri.image.attach(file)
        ri.save!
        ri
      end

      context "when a featured image exists" do
        before { create_featured_image }

        it "shows the Rezept-Highlight label" do
          get root_path
          expect(response.body).to include("Rezept-Highlight")
        end

        it "shows the recipe title" do
          get root_path
          expect(response.body).to include(recipe.title)
        end

        it "links to the recipe" do
          get root_path
          expect(response.body).to include(recipe_path(recipe.slug))
        end
      end

      context "when no featured image exists" do
        it "does not show the Rezept-Highlight label" do
          get root_path
          expect(response.body).not_to include("Rezept-Highlight")
        end
      end

      context "when the featured image belongs to a non-public recipe" do
        it "does not show the featured section" do
          draft_recipe = create(:recipe, user: uploader, is_public: false)
          create_featured_image(recipe: draft_recipe)
          get root_path
          expect(response.body).not_to include("Rezept-Highlight")
        end
      end
    end
  end
end
