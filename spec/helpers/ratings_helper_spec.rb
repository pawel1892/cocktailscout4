require 'rails_helper'

RSpec.describe RatingsHelper, type: :helper do
  describe "#rating_badge_class" do
    it "returns gray class for zero score" do
      expect(helper.rating_badge_class(0)).to eq("bg-gray-400 text-white")
      expect(helper.rating_badge_class(0.0)).to eq("bg-gray-400 text-white")
    end

    it "returns red class for scores below 4" do
      expect(helper.rating_badge_class(1)).to eq("bg-red-600 text-white")
      expect(helper.rating_badge_class(2.5)).to eq("bg-red-600 text-white")
      expect(helper.rating_badge_class(3.99)).to eq("bg-red-600 text-white")
    end

    it "returns orange class for scores 4 to 5.99" do
      expect(helper.rating_badge_class(4)).to eq("bg-orange-500 text-white")
      expect(helper.rating_badge_class(5)).to eq("bg-orange-500 text-white")
      expect(helper.rating_badge_class(5.99)).to eq("bg-orange-500 text-white")
    end

    it "returns yellow class for scores 6 to 7.49" do
      expect(helper.rating_badge_class(6)).to eq("bg-yellow-500 text-white")
      expect(helper.rating_badge_class(7)).to eq("bg-yellow-500 text-white")
      expect(helper.rating_badge_class(7.49)).to eq("bg-yellow-500 text-white")
    end

    it "returns lime class for scores 7.5 to 8.99" do
      expect(helper.rating_badge_class(7.5)).to eq("bg-lime-600 text-white")
      expect(helper.rating_badge_class(8)).to eq("bg-lime-600 text-white")
      expect(helper.rating_badge_class(8.99)).to eq("bg-lime-600 text-white")
    end

    it "returns green class for scores 9 and above" do
      expect(helper.rating_badge_class(9)).to eq("bg-green-700 text-white")
      expect(helper.rating_badge_class(9.5)).to eq("bg-green-700 text-white")
      expect(helper.rating_badge_class(10)).to eq("bg-green-700 text-white")
    end

    it "handles string inputs by converting to float" do
      expect(helper.rating_badge_class("7.5")).to eq("bg-lime-600 text-white")
      expect(helper.rating_badge_class("0")).to eq("bg-gray-400 text-white")
      expect(helper.rating_badge_class("10")).to eq("bg-green-700 text-white")
    end

    it "handles nil by treating as zero" do
      expect(helper.rating_badge_class(nil)).to eq("bg-gray-400 text-white")
    end
  end
end
