module RatingsHelper
  def rating_badge_class(score)
    score = score.to_f
    return "bg-gray-400 text-white" if score.zero?
    return "bg-red-600 text-white" if score < 4
    return "bg-orange-500 text-white" if score < 6
    return "bg-yellow-500 text-white" if score < 7.5
    return "bg-lime-600 text-white" if score < 9
    "bg-green-700 text-white"
  end
end
