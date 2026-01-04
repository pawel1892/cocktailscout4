# todo REFACTOR ME, I AM SO UGLY!

RSpec.shared_context "login as member" do
  let! (:current_user) {create :user}
  include_context 'login as current_user'
end

RSpec.shared_context "login as recipe_moderator" do
  let! (:current_user) {
    current_user = create :user
    current_user.add_role('recipe_moderator')
    current_user
  }

  include_context 'login as current_user'
end

RSpec.shared_context "login as image_moderator" do
  let! (:current_user) {
    current_user = create :user
    current_user.add_role('image_moderator')
    current_user
  }

  include_context 'login as current_user'
end

RSpec.shared_context "login as current_user" do
  before(:each) do
    visit root_path
    click_link 'Anmelden'
    fill_in 'user_login', with: current_user.login
    fill_in 'user_password', with: current_user.password
    click_button 'Anmelden'
  end
end