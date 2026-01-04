# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://www.cocktailscout.de"

SitemapGenerator::Sitemap.create do

  Recipe.find_each do |recipe|
    add recipe_path(recipe), :lastmod => recipe.updated_at
  end

  ForumThread.find_each do |forum_thread|
    add forum_thread_path(forum_thread), :lastmod => forum_thread.forum_posts.last&.updated_at
  end

  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'


end
