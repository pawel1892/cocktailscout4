class ForumSearchController < ApplicationController
  allow_unauthenticated_access only: %i[index]

  def index
    add_breadcrumb "Community", community_path
    add_breadcrumb "Forum", forum_topics_path
    add_breadcrumb "Suche"

    @query = params[:q]

    if @query.present?
      # 1. Get IDs of threads matching title
      title_match_ids = ForumThread.search_by_title(@query).pluck(:id)

      # 2. Get IDs of threads containing matching posts
      post_match_ids = ForumPost.search_by_body(@query).pluck(:forum_thread_id)

      combined_ids = (title_match_ids + post_match_ids).uniq

      # 3. Paginate the threads
      @pagy, @forum_threads = pagy(
        ForumThread.where(id: combined_ids)
                   .includes(:user, :forum_topic)
                   .order(updated_at: :desc)
      )

      # 4. For the visible threads, find the best matching post to link to
      visible_thread_ids = @forum_threads.map(&:id)

      # We find the *first* matching post (by ID) for each visible thread to use as a jump target
      # This effectively deep-links to the first mention of the search term in the thread
      hits = ForumPost.search_by_body(@query)
                      .where(forum_thread_id: visible_thread_ids)
                      .group(:forum_thread_id)
                      .minimum(:id) # Returns hash { thread_id => first_matching_post_id }

      # Load the actual post objects to calculate pagination/anchors
      @search_hits = ForumPost.where(id: hits.values).index_by(&:forum_thread_id)
    else
      @pagy, @forum_threads = pagy(ForumThread.none)
      @search_hits = {}
    end
  end
end
