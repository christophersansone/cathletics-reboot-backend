# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ScheduledEvents" do
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

  describe "GET /api/v1/teams/:team_id/scheduled_events" do
    it "returns scheduled events for the team" do
      get "/api/v1/teams/#{team.id}/scheduled_events",
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
      expect(parsed_body["data"].first.dig("attributes", "title")).to eq(scheduled_event.title)
    end

    it "returns 403 when user cannot read the team" do
      other_user = create(:user)
      get "/api/v1/teams/#{team.id}/scheduled_events",
        headers: auth_headers_for(other_user, organization: organization)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/scheduled_events" do
    it "returns scheduled events for accessible teams in the organization" do
      get "/api/v1/scheduled_events",
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to be >= 1
      ids = parsed_body["data"].map { |d| d["id"].to_i }
      expect(ids).to include(scheduled_event.id)
    end

    it "returns 400 when user has multiple orgs and no X-Org-Id" do
      other_org = create(:organization)
      create(:organization_membership, user: admin, organization: other_org)

      get "/api/v1/scheduled_events", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/v1/scheduled_events/:id" do
    it "returns the scheduled event" do
      get "/api/v1/scheduled_events/#{scheduled_event.id}",
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(parsed_body.dig("data", "attributes", "title")).to eq(scheduled_event.title)
    end

    it "returns 403 when user cannot read the event" do
      other_user = create(:user)
      get "/api/v1/scheduled_events/#{scheduled_event.id}",
        headers: auth_headers_for(other_user, organization: organization)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/scheduled_events" do
    let(:params) do
      {
        data: {
          attributes: {
            title: "Game Day",
            start_at: 2.days.from_now.iso8601,
            end_at: (2.days.from_now + 2.hours).iso8601,
            all_day: false
          },
          relationships: {
            schedulable: { data: { type: "teams", id: team.id.to_s } }
          }
        }
      }
    end

    it "creates a scheduled event" do
      expect {
        post "/api/v1/scheduled_events", params: params,
          headers: auth_headers_for(admin, organization: organization)
      }.to change(ScheduledEvent, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(parsed_body.dig("data", "attributes", "title")).to eq("Game Day")
      created = ScheduledEvent.last
      expect(created.schedulable).to eq(team)
      expect(created.recurs_until).to be_nil
      expect(created.rrule).to be_nil
    end

    it "creates a recurring event with recurs_until and rrule pattern" do
      start_t = Time.zone.parse("2026-09-01 19:00:00")
      recur_body = {
        data: {
          attributes: {
            title: "Weekly practice",
            start_at: start_t.iso8601,
            end_at: (start_t + 2.hours).iso8601,
            all_day: false,
            rrule: "FREQ=WEEKLY;BYDAY=TU",
            recurs_until: "2026-12-15"
          },
          relationships: {
            schedulable: { data: { type: "teams", id: team.id.to_s } }
          }
        }
      }
      expect {
        post "/api/v1/scheduled_events", params: recur_body,
          headers: auth_headers_for(admin, organization: organization)
      }.to change(ScheduledEvent, :count).by(1)

      expect(response).to have_http_status(:created)
      created = ScheduledEvent.last
      expect(created.rrule).to eq("FREQ=WEEKLY;BYDAY=TU")
      expect(created.recurs_until).to eq(Date.new(2026, 12, 15))
      expect(created).to be_recurring
    end

    it "returns 401 without authentication" do
      post "/api/v1/scheduled_events", params: params

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/scheduled_events/:id" do
    it "updates the scheduled event" do
      patch "/api/v1/scheduled_events/#{scheduled_event.id}",
        params: { data: { attributes: { title: "Updated Practice" } } },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(scheduled_event.reload.title).to eq("Updated Practice")
    end

    it "updates with camelCase attributes (JSON:API as sent by Ember)" do
      new_title = "Ember-style Title"
      patch "/api/v1/scheduled_events/#{scheduled_event.id}",
        params: { data: { attributes: { title: new_title, startAt: scheduled_event.start_at.iso8601 } } },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      scheduled_event.reload
      expect(scheduled_event.title).to eq(new_title)
    end

    it "persists cancelledOccurrences with a note (camelCase)" do
      occ_time = scheduled_event.start_at.utc.iso8601
      note = "Canceled due to rain"
      patch "/api/v1/scheduled_events/#{scheduled_event.id}",
        params: {
          data: {
            attributes: {
              cancelledOccurrences: [{ startAt: occ_time, reason: note }]
            }
          }
        },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      scheduled_event.reload
      list = Array.wrap(scheduled_event.cancelled_occurrences)
      expect(list.length).to eq(1)
      expect(list.first["start_at"]).to be_present
      expect(list.first["reason"]).to eq(note)
      attrs = parsed_body.dig("data", "attributes")
      # LegendaryJsonApi uses camelCase keys in JSON (config/initializers/legendary_json_api.rb)
      co = attrs["cancelledOccurrences"]
      expect(co).to be_a(Array)
      expect(co.first["reason"]).to eq(note)
    end

    it "persists exdates as YYYY-MM-dd (camelCase)" do
      zone = Time.find_zone!(scheduled_event.effective_time_zone)
      ex = scheduled_event.start_at.in_time_zone(zone).to_date.iso8601
      patch "/api/v1/scheduled_events/#{scheduled_event.id}",
        params: { data: { attributes: { exdates: [ex] } } },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      scheduled_event.reload
      expect(scheduled_event.exdates).to eq([ex])
    end

    it "rejects non-calendar exdate strings" do
      patch "/api/v1/scheduled_events/#{scheduled_event.id}",
        params: { data: { attributes: { exdates: [scheduled_event.start_at.utc.iso8601] } } },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "persists cancelledFrom and cancellationReason (camelCase)" do
      from = scheduled_event.start_at.utc.iso8601
      patch "/api/v1/scheduled_events/#{scheduled_event.id}",
        params: {
          data: {
            attributes: {
              cancelledFrom: from,
              cancellationReason: "League-wide shutdown"
            }
          }
        },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      scheduled_event.reload
      expect(scheduled_event.cancelled_from).to be_present
      expect(scheduled_event.cancellation_reason).to eq("League-wide shutdown")
    end

    it "appends to cancelled_occurrences when merging client sends full array" do
      scheduled_event.update!(cancelled_occurrences: [])
      first = (scheduled_event.start_at + 1.hour).utc.iso8601
      second = (scheduled_event.start_at + 2.hours).utc.iso8601
      patch "/api/v1/scheduled_events/#{scheduled_event.id}",
        params: {
          data: {
            attributes: {
              cancelledOccurrences: [
                { startAt: first, reason: "A" },
                { startAt: second, reason: "B" }
              ]
            }
          }
        },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      scheduled_event.reload
      expect(scheduled_event.cancelled_occurrences.length).to eq(2)
    end
  end

  describe "DELETE /api/v1/scheduled_events/:id" do
    it "soft deletes the scheduled event" do
      delete "/api/v1/scheduled_events/#{scheduled_event.id}",
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:no_content)
      expect(scheduled_event.reload).to be_deleted
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
