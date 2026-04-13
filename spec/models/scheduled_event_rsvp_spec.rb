# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduledEventRsvp do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:scheduled_event_rsvp)).to be_valid
    end

    it "requires response" do
      expect(build(:scheduled_event_rsvp, response: nil)).not_to be_valid
    end

    it "requires occurrence_start_at" do
      expect(build(:scheduled_event_rsvp, occurrence_start_at: nil)).not_to be_valid
    end

    it "prevents duplicate user per occurrence" do
      existing = create(:scheduled_event_rsvp)
      duplicate = build(:scheduled_event_rsvp,
        scheduled_event: existing.scheduled_event,
        user: existing.user,
        occurrence_start_at: existing.occurrence_start_at)
      expect(duplicate).not_to be_valid
    end

    it "allows same user on different occurrences" do
      event = create(:scheduled_event, rsvp_mode: :full)
      user = create(:user)
      create(:scheduled_event_rsvp,
        scheduled_event: event,
        user: user,
        occurrence_start_at: event.start_at)
      second = build(:scheduled_event_rsvp,
        scheduled_event: event,
        user: user,
        occurrence_start_at: event.start_at + 1.week)
      expect(second).to be_valid
    end

    it "allows re-RSVP after soft delete" do
      rsvp = create(:scheduled_event_rsvp)
      rsvp.mark_as_deleted!
      new_rsvp = build(:scheduled_event_rsvp,
        scheduled_event: rsvp.scheduled_event,
        user: rsvp.user,
        occurrence_start_at: rsvp.occurrence_start_at)
      expect(new_rsvp).to be_valid
    end
  end

  describe "rsvp_mode validation" do
    it "rejects RSVPs when rsvp_mode is none" do
      event = create(:scheduled_event, rsvp_mode: :none)
      rsvp = build(:scheduled_event_rsvp, scheduled_event: event)
      expect(rsvp).not_to be_valid
      expect(rsvp.errors[:base]).to include("RSVPs are not enabled for this event")
    end

    it "rejects yes response for regrets_only events" do
      event = create(:scheduled_event, rsvp_mode: :regrets_only)
      rsvp = build(:scheduled_event_rsvp, scheduled_event: event, response: :yes)
      expect(rsvp).not_to be_valid
      expect(rsvp.errors[:response]).to include("must be 'no' for regrets-only events")
    end

    it "rejects maybe response for regrets_only events" do
      event = create(:scheduled_event, rsvp_mode: :regrets_only)
      rsvp = build(:scheduled_event_rsvp, scheduled_event: event, response: :maybe)
      expect(rsvp).not_to be_valid
    end

    it "allows no response for regrets_only events" do
      event = create(:scheduled_event, rsvp_mode: :regrets_only)
      rsvp = build(:scheduled_event_rsvp, scheduled_event: event, response: :no)
      expect(rsvp).to be_valid
    end

    it "allows yes response for full events" do
      event = create(:scheduled_event, rsvp_mode: :full)
      rsvp = build(:scheduled_event_rsvp, scheduled_event: event, response: :yes)
      expect(rsvp).to be_valid
    end

    it "allows no response for full events" do
      event = create(:scheduled_event, rsvp_mode: :full)
      rsvp = build(:scheduled_event_rsvp, scheduled_event: event, response: :no)
      expect(rsvp).to be_valid
    end

    it "allows maybe response for full events" do
      event = create(:scheduled_event, rsvp_mode: :full)
      rsvp = build(:scheduled_event_rsvp, scheduled_event: event, response: :maybe)
      expect(rsvp).to be_valid
    end
  end

  describe "enums" do
    it { expect(build(:scheduled_event_rsvp, response: :yes)).to be_response_yes }
    it { expect(build(:scheduled_event_rsvp, response: :no)).to be_response_no }
    it { expect(build(:scheduled_event_rsvp, response: :maybe)).to be_response_maybe }
  end

  describe "associations" do
    it "belongs to scheduled_event" do
      rsvp = create(:scheduled_event_rsvp)
      expect(rsvp.scheduled_event).to be_a(ScheduledEvent)
    end

    it "belongs to user" do
      rsvp = create(:scheduled_event_rsvp)
      expect(rsvp.user).to be_a(User)
    end

    it "optionally belongs to responded_by" do
      rsvp = build(:scheduled_event_rsvp, responded_by: nil)
      expect(rsvp).to be_valid
    end
  end

  describe "soft delete" do
    it "soft deletes via mark_as_deleted!" do
      rsvp = create(:scheduled_event_rsvp)
      rsvp.mark_as_deleted!
      expect(rsvp).to be_deleted
      expect(ScheduledEventRsvp.count).to eq(0)
      expect(ScheduledEventRsvp.with_deleted.count).to eq(1)
    end
  end
end
