json.extract! shoutbox_entry, :id, :content, :created_at
json.time_ago time_ago_in_words(shoutbox_entry.created_at)
json.user do
  json.login shoutbox_entry.user.login
  json.profile_link user_profile_path(shoutbox_entry.user.user_profile)
end
