require 'rails_helper'

RSpec.describe ForumTopic, type: :model do
  it { is_expected.to have_many(:forum_threads) }
end
