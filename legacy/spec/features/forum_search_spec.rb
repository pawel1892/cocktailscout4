require 'rails_helper'
describe 'ForumSearch' do
  context 'when query is part of thread title' do

    let!(:forum_thread) { create :forum_thread, title: 'Deine Mutter' }
    it 'shows thread on result page' do
      visit(forum_topics_path)
      fill_in(:forum_search_query, with: 'Mutter')
      click_button('forum_search_button')
      expect(page).to have_content 'Deine Mutter'
    end
  end

  context 'when query is part of post content' do
    let!(:forum_post) { create :forum_post, content: 'Mutter isst.' }
    it 'shows thread on result page' do
      visit(forum_topics_path)
      fill_in(:forum_search_query, with: 'Mutter')
      click_button('forum_search_button')
      expect(page).to have_content forum_post.forum_thread.title
    end
  end
end
