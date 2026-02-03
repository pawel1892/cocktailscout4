# frozen_string_literal: true

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://#{ENV.fetch('APP_HOST', 'www.cocktailscout.de')}"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"

SitemapGenerator::Sitemap.create do
  # Static pages
  add root_path, priority: 1.0, changefreq: "daily"
  add recipes_path, priority: 0.9, changefreq: "daily"
  add forum_topics_path, priority: 0.8, changefreq: "daily"
  add community_path, priority: 0.7, changefreq: "weekly"
  add users_path, priority: 0.6, changefreq: "weekly"
  add recipe_images_path, priority: 0.6, changefreq: "daily"
  add top_lists_path, priority: 0.5, changefreq: "weekly"

  # All recipes (using slug-based URLs)
  Recipe.find_each do |recipe|
    add recipe_path(recipe), priority: 0.8, changefreq: "weekly", lastmod: recipe.updated_at
  end

  # Forum topics
  ForumTopic.find_each do |topic|
    add forum_topic_path(topic), priority: 0.7, changefreq: "daily", lastmod: topic.updated_at
  end

  # Forum threads (non-deleted)
  ForumThread.where(deleted: false).find_each do |thread|
    add forum_thread_path(thread), priority: 0.7, changefreq: "daily", lastmod: thread.updated_at
  end

  # Tags (from acts-as-taggable-on)
  ActsAsTaggableOn::Tag.find_each do |tag|
    add tag_path(tag: tag.name), priority: 0.6, changefreq: "weekly"
  end
end
