require 'rails_helper'

describe User do

  it "has a valid factory" do
    expect(create(:user)).to be_valid
  end

  it "is invalid without a login" do
    expect(build(:user, login: nil)).to_not be_valid
  end

  it "is invalid without a email" do
    expect(build(:user, email: nil)).to_not be_valid
  end

  it "is invalid with a duplicate email" do
    expect(create(:user, email: "abc@example.com")).to be_valid
    expect(build(:user, email: "abc@example.com")).to_not be_valid
  end

  it "is invalid without a login" do
    expect(build(:user, login: nil)).to_not be_valid
  end

  it "is invalid with a login" do
    expect(create(:user, login: "abc")).to be_valid
    expect(build(:user, login: "abc")).to_not be_valid
  end

  it "has role member after creation" do
    user = create(:user)
    expect(user.role?('member')).to be true
  end

  describe "add roles" do
    before :each do
      @user = create(:user)
    end

    context "add existing member role" do
      it {
        expect {
          @user.add_role 'member'
        }.to_not change(@user.roles, :count)
      }
    end

    context "add new admin role" do
      it {
        expect {
          @user.add_role 'admin'
        }.to change(@user.roles, :count).by(1)
      }
    end

  end

  describe "favorite recipes" do
    context "favorite recipes scope" do
      before :each do
        @user = create(:user)
        @recipe_fav = create(:recipe)
        @recipe_fav2 = create(:recipe)
        @recipe_non_fav = create(:recipe)
        @recipe_not_in_db = create(:recipe)
        @user.user_recipes << UserRecipe.new(:recipe_id => @recipe_fav.id, :dimension => 'favorite')
        @user.user_recipes << UserRecipe.new(:recipe_id => @recipe_fav2.id, :dimension => 'favorite')
        @user.user_recipes << UserRecipe.new(:recipe_id => @recipe_non_fav.id)
      end
      it ".favorite_recipes contains favorites" do
        expect(@user.favorite_recipes).to include(@recipe_fav, @recipe_fav2)
      end
      it ".favorite_recipes does not include wrong recipes" do
        expect(@user.favorite_recipes).to_not include(@recipe_non_fav, @recipe_not_in_db)
      end
    end
    context "favorite recipes" do
      before :each do
        @user = create(:user)
        @user2 = create(:user)
        @recipe_fav = create(:recipe)
        @recipe_fav2 = create(:recipe)
        @user2.user_recipes << UserRecipe.new(:recipe_id => @recipe_fav.id, :dimension => 'favorite')
        @user2.user_recipes << UserRecipe.new(:recipe_id => @recipe_fav2.id, :dimension => 'favorite')
      end
      it "add favorite recipe" do
        @user.add_favorite_recipe @recipe_fav.id
        expect(@user.favorite_recipes).to include(@recipe_fav)
      end
      it "do not add favorite recipe twice" do
        @user.add_favorite_recipe @recipe_fav.id
        expect{@user.add_favorite_recipe @recipe_fav.id}.to_not change{@user.favorite_recipes.count}
      end
      it "remove favorite recipe" do
        @user2.remove_favorite_recipe @recipe_fav.id
        expect(@user2.favorite_recipes).to_not include(@recipe_fav)
      end
      it "remove favorite recipe removes only one recipe" do
        @user2.remove_favorite_recipe @recipe_fav.id
        expect(@user2.favorite_recipes).to include(@recipe_fav2)
      end
    end
  end

  describe "mybar ingredients" do
    context "mybar ingredients scope" do
      before :each do
        @user = create(:user)
        @my_bar_ingredient = create(:ingredient)
        @my_bar_ingredient2 = create(:ingredient)
        @not_in_my_bar_ingredient = create(:ingredient)
        @unused_ingredient = create(:ingredient)
        @user.user_ingredients << UserIngredient.new(:ingredient_id => @my_bar_ingredient.id, :dimension => 'mybar')
        @user.user_ingredients << UserIngredient.new(:ingredient_id => @my_bar_ingredient2.id, :dimension => 'mybar')
        @user.user_ingredients << UserIngredient.new(:ingredient_id => @not_in_my_bar_ingredient.id)
      end
      it ".mybar_ingredients contains ingredient1 and 2" do
        expect(@user.mybar_ingredients).to include(@my_bar_ingredient, @my_bar_ingredient2)
      end
      it ".mybar_ingredients does not contain unsed ingredients" do
        expect(@user.mybar_ingredients).to_not include(@not_in_my_bar_ingredient, @unused_ingredient)
      end
    end
    context "add and remove mybar ingredients" do
      before :each do
        @user = create(:user)
        @user2 = create(:user)
        @my_bar_ingredient = create(:ingredient)
        @my_bar_ingredient2 = create(:ingredient)
        @user2.user_ingredients << UserIngredient.new(:ingredient_id => @my_bar_ingredient.id, :dimension => 'mybar')
        @user2.user_ingredients << UserIngredient.new(:ingredient_id => @my_bar_ingredient2.id, :dimension => 'mybar')
      end
      it "add ingredient to mybar" do
        @user.add_mybar_ingredient @my_bar_ingredient.id
        expect(@user.mybar_ingredients).to include(@my_bar_ingredient)
      end
      it "do not add ingredient if it already exists" do
        @user.add_mybar_ingredient @my_bar_ingredient.id
        expect{@user.add_mybar_ingredient @my_bar_ingredient.id}.to_not change{@user.mybar_ingredients}
      end
      it "remove mybar ingredient" do
        @user2.remove_mybar_ingredient @my_bar_ingredient.id
        expect(@user2.mybar_ingredients).to_not include(@my_bar_ingredient)
      end
      it "remove mybar ingredient should not remove other ingredients" do
        @user2.remove_mybar_ingredient @my_bar_ingredient.id
        expect(@user2.mybar_ingredients).to include(@my_bar_ingredient2)
      end
    end
  end

  describe "user profiles" do
    context "user without profile" do
      it ".user_profile should create a new profile" do
        user = create(:user)
        user.user_profile
        expect(user.user_profile.class.to_s).to eq "UserProfile"
      end
    end
    context "user with profile" do
      it ".user_profile should return associated profile" do
        user = create(:user)
        user_profile = create(:user_profile, :user => user )
        expect(user.user_profile).to eq user_profile
      end
    end
  end

  describe '.is_online?' do
    context 'user was never active' do
      let! (:user) { create :user, last_active_at: nil }
      it 'returns false' do
        expect(user.is_online?).to eq false
      end
    end

    context 'user was active last 10 minutes' do
      let! (:user) { create :user, last_active_at: Time.now.utc - 5.minutes }
      it 'returns true' do
        expect(user.is_online?).to eq true
      end
    end

    context 'user was active last day' do
      let (:user) { create :user, last_active_at: Time.now.utc - 1.day }
      it 'returns false' do
        expect(user.is_online?).to eq false
      end
    end

  end

end
