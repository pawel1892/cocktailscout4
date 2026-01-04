require 'rails_helper'

describe 'index' do

  let! (:blog_entries) {create_list :blog_entry, 2}

  it 'lists blog entries' do

    visit blog_entries_path
    expect(page).to have_content blog_entries.second.teaser
    expect(page).to have_content blog_entries.first.user.login

    # save_and_open_page
  end

  it 'shows blog entry' do

    visit blog_entry_path(blog_entries.second.id)
    expect(page).to have_content blog_entries.second.user.login
    expect(page).to have_content blog_entries.second.content
    expect(page).to have_content blog_entries.second.title
  end

end