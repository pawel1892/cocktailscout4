require 'rails_helper'

describe 'Login' do

  it "login as member" do
    user = create(:user)

    visit root_path
    click_link 'Anmelden'
    fill_in 'user_login', with: user.login
    fill_in 'user_password', with: user.password
    click_button 'Anmelden'

    expect(page).to have_content user.login
  end

  it "login with invalid passwort" do
    user = create(:user)

    visit root_path
    click_link 'Anmelden'
    fill_in 'user_login', with: user.login
    fill_in 'user_password', with: user.password + 'invalid'
    click_button 'Anmelden'

    expect(page).to_not have_content 'Angemeldet als ' +  user.email
  end
end

describe 'index' do

  let! (:users) {create_list :user, 53}

  it 'lists users' do

    UserRank.all.each { |u| u.update_attribute(:points, 15)}
    UserRank.second.update_attribute(:points, 1)
    user = create :user, :with_recipes

    visit users_path
    expect(page).to have_content UserRank.where(points: 15).first.user.login
    expect(page).to have_link('2', href: users_path(:page => 2))

    visit users_path(:page => 2)
    expect(page).to have_content UserRank.where(points: 1).first.user.login

    # save_and_open_page
  end

end

describe 'activity tracking' do
  include_context 'login as member'
  it 'sets last_active_at field' do
    visit root_path
    current_user.reload
    expect(current_user.last_active_at).to be >= (Time.now.utc - 10.seconds)
    expect(current_user.last_active_at).to be <= (Time.now.utc)
  end
end

describe 'daily login count' do
  let! (:current_user) { create :user, daily_login_count: 3 }
  include_context 'login as current_user'
  context 'first login fo the day' do
    it 'increments the daily login count after login' do
      expect(current_user.reload.daily_login_count).to eq 4
    end
  end
  context 'first and second login for the day' do
    it 'does not change daily login count after second login' do
      expect(current_user.reload.daily_login_count).to eq 4
      click_link 'Abmelden'
      visit root_path
      click_link 'Anmelden'
      fill_in 'user_login', with: current_user.login
      fill_in 'user_password', with: current_user.password
      click_button 'Anmelden'
      expect(current_user.reload.daily_login_count).to eq 4
    end
  end
end