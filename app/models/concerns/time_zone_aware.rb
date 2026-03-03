module TimeZoneAware
  extend ActiveSupport::Concern

  included do
    validate :validate_iana_time_zone, if: -> { time_zone.present? }
  end

  private

  def validate_iana_time_zone
    unless TZInfo::Timezone.all_identifiers.include?(time_zone)
      errors.add(:time_zone, "is not a valid IANA time zone identifier")
    end
  end
end
