# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ScheduledEventOccurrences" do
  let(:admin) { create(:user) }
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let(:season) { create(:season, activity_type: activity_type) }
  let(:league) { create(:league, season: season) }
  let!(:team) { create(:team, league: league) }
  let!(:scheduled_event) { create(:scheduled_event, schedulable: team) }

  before do
    create(:organization_membership, :admin, user: admin, organization: organization)
  end

  describe "GET /api/v1/scheduled_event_occurrences" do
    let(:from) { 1.day.ago.iso8601 }
    let(:to) { 1.month.from_now.iso8601 }

    it "returns 401 without authentication" do
      get "/api/v1/scheduled_event_occurrences",
        params: { schedulable_type: "Team", schedulable_id: team.id, from: from, to: to }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 when schedulable_type and schedulable_id are missing" do
      get "/api/v1/scheduled_event_occurrences",
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 200 with text/calendar and iCal content" do
      get "/api/v1/scheduled_event_occurrences",
        params: { schedulable_type: "Team", schedulable_id: team.id, from: from, to: to },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/calendar")
      expect(response.body).to include("BEGIN:VCALENDAR")
      expect(response.body).to include("END:VCALENDAR")
      expect(response.body).to include("BEGIN:VEVENT")
      expect(response.body).to include(scheduled_event.title)
    end

    it "emits STATUS:CANCELLED, X-CANCELLATION-REASON, and UTC Zulu DTSTART/DTEND for cancelled occurrences" do
      t = scheduled_event.start_at
      scheduled_event.update!(
        cancelled_occurrences: [{ "start_at" => t.utc.iso8601, "reason" => "Rain check" }]
      )
      get "/api/v1/scheduled_event_occurrences",
        params: { schedulable_type: "Team", schedulable_id: team.id, from: from, to: to },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("STATUS:CANCELLED")
      expect(body).to include("X-CANCELLATION-REASON:Rain check")
      expect(body).to match(/DTSTART:\d{8}T\d{6}Z/)
      expect(body).to match(/DTEND:\d{8}T\d{6}Z/)
    end

    it "returns 403 when user cannot read the schedulable" do
      other_user = create(:user)
      get "/api/v1/scheduled_event_occurrences",
        params: { schedulable_type: "Team", schedulable_id: team.id, from: from, to: to },
        headers: auth_headers_for(other_user, organization: organization)

      expect(response).to have_http_status(:forbidden)
    end

    it "omits exdate'd occurrences from the iCal (YYYY-MM-dd)" do
      series_start = Time.zone.parse("2026-06-09 19:00:00")
      series_end = Time.zone.parse("2026-06-09 20:30:00")
      recurring = create(
        :scheduled_event,
        schedulable: team,
        title: "Weekly practice",
        start_at: series_start,
        end_at: series_end,
        rrule: "FREQ=WEEKLY;BYDAY=TU",
        recurs_until: Date.new(2026, 6, 30),
        exdates: ["2026-06-16"]
      )
      window_from = series_start - 1.day
      window_to = series_start + 1.month
      get "/api/v1/scheduled_event_occurrences",
        params: {
          schedulable_type: "Team",
          schedulable_id: team.id,
          from: window_from.iso8601,
          to: window_to.iso8601
        },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      body = response.body
      excluded_ts = Time.zone.parse("2026-06-16 19:00:00").utc.to_i
      expect(body).not_to include("cathletics-event-#{recurring.id}-#{excluded_ts}@cathletics")
      # Jun 9, 23, 30 still present (4 Tuesdays minus one exdate)
      expect(body.scan("BEGIN:VEVENT").size).to eq(3)
    end
  end
end
