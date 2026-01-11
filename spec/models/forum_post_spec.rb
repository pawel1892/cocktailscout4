require 'rails_helper'

RSpec.describe ForumPost, type: :model do
  it { is_expected.to belong_to(:forum_thread) }
  it { is_expected.to belong_to(:user).optional }
end
