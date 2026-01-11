require 'rails_helper'

RSpec.describe ForumThread, type: :model do
  include_examples "visitable"

  it { is_expected.to belong_to(:forum_topic) }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to have_many(:forum_posts).dependent(:destroy) }
end
