# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduledEvent, type: :model do
  let(:team) { create(:team) }

  describe "exdates validation" do
    it "accepts ISO 8601 calendar dates" do
      event = build(:scheduled_event, schedulable: team, exdates: ["2026-06-10"])
      expect(event).to be_valid
    end

    it "rejects full timestamps" do
      event = build(:scheduled_event, schedulable: team, exdates: [Time.zone.parse("2026-06-10 19:00:00").utc.iso8601])
      expect(event).not_to be_valid
      expect(event.errors[:exdates]).to be_present
    end

    it "rejects invalid calendar dates" do
      event = build(:scheduled_event, schedulable: team, exdates: ["2026-02-31"])
      expect(event).not_to be_valid
      expect(event.errors[:exdates]).to be_present
    end

    it "rejects non-string entries" do
      event = build(:scheduled_event, schedulable: team, exdates: [2026])
      expect(event).not_to be_valid
      expect(event.errors[:exdates]).to be_present
    end
  end

  describe "#occurrences_between — single event" do
    let(:start_at) { Time.zone.parse("2026-06-10 19:00:00") }
    let(:end_at) { Time.zone.parse("2026-06-10 20:30:00") }
    let(:window_from) { start_at - 1.day }
    let(:window_to) { start_at + 1.day }

    it "returns one occurrence in range" do
      event = create(:scheduled_event, schedulable: team, title: "Game", start_at: start_at, end_at: end_at, rrule: nil)
      occs = event.occurrences_between(window_from, window_to)
      expect(occs.length).to eq(1)
      expect(occs.first[:cancelled]).to be false
      expect(occs.first[:cancellation_reason]).to be_nil
    end

    it "omits removed single events when exdate is YYYY-MM-dd in event zone" do
      event = create(
        :scheduled_event,
        schedulable: team,
        start_at: start_at,
        end_at: end_at,
        rrule: nil,
        exdates: ["2026-06-10"]
      )
      expect(event.occurrences_between(window_from, window_to)).to eq([])
    end

    it "marks cancelled with per-occurrence note" do
      event = create(
        :scheduled_event,
        schedulable: team,
        start_at: start_at,
        end_at: end_at,
        rrule: nil,
        cancelled_occurrences: [{ "start_at" => start_at.utc.iso8601, "reason" => "Rain" }]
      )
      occs = event.occurrences_between(window_from, window_to)
      expect(occs.first[:cancelled]).to be true
      expect(occs.first[:cancellation_reason]).to eq("Rain")
    end

    it "matches per-occurrence cancel with symbol keys (assign_attributes-style hashes)" do
      event = create(
        :scheduled_event,
        schedulable: team,
        start_at: start_at,
        end_at: end_at,
        rrule: nil,
        cancelled_occurrences: [{ start_at: start_at.utc.iso8601, reason: "Field closed" }]
      )
      occs = event.occurrences_between(window_from, window_to)
      expect(occs.first[:cancelled]).to be true
      expect(occs.first[:cancellation_reason]).to eq("Field closed")
    end

    it "cancels from cancelled_from onward with series reason" do
      event = create(
        :scheduled_event,
        schedulable: team,
        start_at: start_at,
        end_at: end_at,
        rrule: nil,
        cancelled_from: start_at,
        cancellation_reason: "Season ended early"
      )
      occs = event.occurrences_between(window_from, window_to)
      expect(occs.first[:cancelled]).to be true
      expect(occs.first[:cancellation_reason]).to eq("Season ended early")
    end
  end

  describe "#occurrences_between — recurring event" do
    # Tuesdays 19:00 UTC — Jun 9, 16, 23, 30
    let(:series_start) { Time.zone.parse("2026-06-09 19:00:00") }
    let(:series_end) { Time.zone.parse("2026-06-09 20:30:00") }
    let(:rrule) { "FREQ=WEEKLY;BYDAY=TU" }
    let(:recurs_until) { Date.new(2026, 6, 30) }

    let(:event) do
      create(
        :scheduled_event,
        schedulable: team,
        start_at: series_start,
        end_at: series_end,
        rrule: rrule,
        recurs_until: recurs_until
      )
    end

    it "clears rrule when recurs_until is absent (not recurring)" do
      e = build(:scheduled_event, schedulable: team, start_at: series_start, end_at: series_end, rrule: rrule, recurs_until: nil)
      expect(e).to be_valid
      expect(e.rrule).to be_nil
      expect(e).not_to be_recurring
    end

    it "requires rrule when recurs_until is set" do
      e = build(:scheduled_event, schedulable: team, start_at: series_start, end_at: series_end, rrule: nil, recurs_until: recurs_until)
      expect(e).not_to be_valid
      expect(e.errors[:rrule]).to be_present
    end

    it "expands multiple occurrences" do
      occs = event.occurrences_between(series_start - 1.day, series_start + 1.month)
      expect(occs.length).to eq(4)
      expect(occs.map { |o| o[:cancelled] }).to all(be false)
    end

    it "cancels one occurrence by start time with a note" do
      second = Time.zone.parse("2026-06-16 19:00:00").utc
      event.update!(
        cancelled_occurrences: [{ "start_at" => second.iso8601, "reason" => "Heat advisory" }]
      )
      occs = event.occurrences_between(series_start - 1.day, series_start + 1.month)
      cancelled = occs.find { |o| o[:start_at].to_i == second.to_i }
      expect(cancelled[:cancelled]).to be true
      expect(cancelled[:cancellation_reason]).to eq("Heat advisory")
      expect(occs.count { |o| o[:cancelled] }).to eq(1)
    end

    it "cancels all occurrences from cancelled_from forward; earlier still expand" do
      cutoff = Time.zone.parse("2026-06-23 19:00:00").utc
      event.update!(
        cancelled_from: cutoff,
        cancellation_reason: "Coach unavailable"
      )
      occs = event.occurrences_between(series_start - 1.day, series_start + 1.month)
      expect(occs.count).to eq(4)
      before = occs.select { |o| o[:start_at] < cutoff }
      after = occs.select { |o| o[:start_at] >= cutoff }
      expect(before).not_to be_empty
      expect(after).not_to be_empty
      expect(before.map { |o| o[:cancelled] }).to all(be false)
      expect(after.map { |o| o[:cancelled] }).to all(be true)
      expect(after.first[:cancellation_reason]).to eq("Coach unavailable")
    end

    it "removes one occurrence via exdate (YYYY-MM-dd)" do
      event.update!(exdates: ["2026-06-16"])
      occs = event.occurrences_between(series_start - 1.day, series_start + 1.month)
      second = Time.zone.parse("2026-06-16 19:00:00").utc
      expect(occs.length).to eq(3)
      expect(occs.none? { |o| o[:start_at].to_i == second.to_i }).to be true
    end
  end
end
