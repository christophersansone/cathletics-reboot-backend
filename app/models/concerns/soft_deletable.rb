module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :undeleted, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }

    default_scope { undeleted }
  end

  def mark_as_deleted!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end

  module ClassMethods
    def with_deleted
      unscope(where: :deleted_at)
    end
  end
end
