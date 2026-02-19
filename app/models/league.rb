class League < ApplicationRecord
  include SoftDeletable

  enum :gender, { male: 0, female: 1 }

  belongs_to :season
  has_one :activity_type, through: :season
  has_one :organization, through: :activity_type

  has_many :teams, dependent: :destroy
  has_many :registrations, dependent: :destroy

  validates :season, presence: true

  def full?
    capacity.present? && registrations.count >= capacity
  end

  def auto_generated_name
    parts = []
    parts << grade_range_label if min_grade.present? || max_grade.present?
    parts << age_range_label if min_age.present? || max_age.present?
    parts << gender&.capitalize
    parts << activity_type&.name
    parts.compact_blank.join(" ")
  end

  private

  def grade_range_label
    if min_grade.present? && max_grade.present?
      min_grade == max_grade ? grade_label(min_grade) : "#{grade_label(min_grade)}-#{grade_label(max_grade)}"
    elsif min_grade.present?
      "#{grade_label(min_grade)}+"
    elsif max_grade.present?
      "Up to #{grade_label(max_grade)}"
    end
  end

  def age_range_label
    if min_age.present? && max_age.present?
      min_age == max_age ? "Age #{min_age}" : "Ages #{min_age}-#{max_age}"
    elsif min_age.present?
      "Ages #{min_age}+"
    elsif max_age.present?
      "Ages up to #{max_age}"
    end
  end

  def grade_label(grade)
    case grade
    when -1 then "Pre-K"
    when 0 then "K"
    else grade.ordinalize
    end
  end
end
