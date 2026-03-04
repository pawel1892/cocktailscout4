module ActivityStreamEnrichable
  extend ActiveSupport::Concern

  def enrich_image_events!(events)
    image_event_ids = events.select { |e| e[:type] == "recipe_image" }
                            .map { |e| e.dig(:meta, :recipe_image_id) }
    return if image_event_ids.empty?

    images = RecipeImage.where(id: image_event_ids).index_by(&:id)
    events.each do |event|
      next unless event[:type] == "recipe_image"
      img = images[event.dig(:meta, :recipe_image_id)]
      next unless img&.image&.attached?
      event[:meta][:thumb_url] = url_for(img.image.variant(:thumb))
    end
  end
end
