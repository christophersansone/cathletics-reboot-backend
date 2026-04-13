# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ScheduledEventRsvps" do
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let(:season) { create(:season, activity_type: activity_type) }
  let(:league) { create(:league, season: season) }
  let(:team) { create(:team, league: league) }
  let(:scheduled_event) { create(:scheduled_event, schedulable: team, rsvp_mode: :full) }

  let(:admin) { create(:user) }
  let(:parent) { create(:user) }
  let(:child) { create(:user, :child) }
  let(:family) { create(:family) }

  before do
    create(:organization_membership, :admin, user: admin, organization: organization)
    create(:organization_membership, user: parent, organization: organization)
    create(:family_membership, family: family, user: parent, role: :parent)
    create(:family_membership, family: family, user: child, role: :child)
    create(:team_membership, team: team, user: child, role: :player)
  end

  describe "GET /api/v1/scheduled_event_rsvps" do
    let!(:rsvp) do
      create(:scheduled_event_rsvp,
        scheduled_event: scheduled_event,
        user: child,
        responded_by: parent,
        occurrence_start_at: scheduled_event.start_at)
    end

    it "returns RSVPs for the event" do
      get "/api/v1/scheduled_event_rsvps",
        params: { scheduled_event_id: scheduled_event.id },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
      expect(parsed_body["data"].first.dig("attributes", "response")).to eq("yes")
    end

    it "filters by occurrence_start_at" do
      other_rsvp = create(:scheduled_event_rsvp,
        scheduled_event: scheduled_event,
        occurrence_start_at: scheduled_event.start_at + 1.week)

      get "/api/v1/scheduled_event_rsvps",
        params: {
          scheduled_event_id: scheduled_event.id,
          occurrence_start_at: scheduled_event.start_at.iso8601
        },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      ids = parsed_body["data"].map { |d| d["id"].to_i }
      expect(ids).to include(rsvp.id)
      expect(ids).not_to include(other_rsvp.id)
    end

    it "allows a member to read RSVPs for their team's events" do
      get "/api/v1/scheduled_event_rsvps",
        params: { scheduled_event_id: scheduled_event.id },
        headers: auth_headers_for(parent, organization: organization)

      expect(response).to have_http_status(:ok)
    end

    it "returns 403 for unauthorized users" do
      outsider = create(:user)
      get "/api/v1/scheduled_event_rsvps",
        params: { scheduled_event_id: scheduled_event.id },
        headers: auth_headers_for(outsider, organization: organization)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/scheduled_event_rsvps" do
    let(:params) do
      {
        data: {
          attributes: {
            response: "yes",
            occurrenceStartAt: scheduled_event.start_at.iso8601,
            note: "Will be 5 min late"
          },
          relationships: {
            scheduledEvent: { data: { type: "scheduled-events", id: scheduled_event.id.to_s } },
            user: { data: { type: "users", id: child.id.to_s } }
          }
        }
      }
    end

    it "creates an RSVP and sets responded_by to current user" do
      expect {
        post "/api/v1/scheduled_event_rsvps",
          params: params,
          headers: auth_headers_for(parent, organization: organization)
      }.to change(ScheduledEventRsvp, :count).by(1)

      expect(response).to have_http_status(:created)
      rsvp = ScheduledEventRsvp.last
      expect(rsvp.user).to eq(child)
      expect(rsvp.responded_by).to eq(parent)
      expect(rsvp).to be_response_yes
      expect(rsvp.note).to eq("Will be 5 min late")
    end

    it "rejects RSVP when rsvp_mode is none" do
      scheduled_event.update!(rsvp_mode: :none)

      post "/api/v1/scheduled_event_rsvps",
        params: params,
        headers: auth_headers_for(parent, organization: organization)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects yes response for regrets_only events" do
      scheduled_event.update!(rsvp_mode: :regrets_only)

      post "/api/v1/scheduled_event_rsvps",
        params: params,
        headers: auth_headers_for(parent, organization: organization)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows no response for regrets_only events" do
      scheduled_event.update!(rsvp_mode: :regrets_only)
      regrets_params = {
        data: {
          attributes: {
            response: "no",
            occurrenceStartAt: scheduled_event.start_at.iso8601
          },
          relationships: {
            scheduledEvent: { data: { type: "scheduled-events", id: scheduled_event.id.to_s } },
            user: { data: { type: "users", id: child.id.to_s } }
          }
        }
      }

      expect {
        post "/api/v1/scheduled_event_rsvps",
          params: regrets_params,
          headers: auth_headers_for(parent, organization: organization)
      }.to change(ScheduledEventRsvp, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(ScheduledEventRsvp.last).to be_response_no
    end

    it "returns 401 without authentication" do
      post "/api/v1/scheduled_event_rsvps", params: params

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/scheduled_event_rsvps/:id" do
    let!(:rsvp) do
      create(:scheduled_event_rsvp,
        scheduled_event: scheduled_event,
        user: child,
        responded_by: parent,
        occurrence_start_at: scheduled_event.start_at,
        response: :yes)
    end

    it "updates the response" do
      patch "/api/v1/scheduled_event_rsvps/#{rsvp.id}",
        params: { data: { attributes: { response: "no", note: "Sick" } } },
        headers: auth_headers_for(parent, organization: organization)

      expect(response).to have_http_status(:ok)
      rsvp.reload
      expect(rsvp).to be_response_no
      expect(rsvp.note).to eq("Sick")
    end

    it "allows admin to update any RSVP" do
      patch "/api/v1/scheduled_event_rsvps/#{rsvp.id}",
        params: { data: { attributes: { response: "maybe" } } },
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(rsvp.reload).to be_response_maybe
    end
  end

  describe "DELETE /api/v1/scheduled_event_rsvps/:id" do
    let!(:rsvp) do
      create(:scheduled_event_rsvp,
        scheduled_event: scheduled_event,
        user: child,
        responded_by: parent,
        occurrence_start_at: scheduled_event.start_at)
    end

    it "soft deletes the RSVP" do
      delete "/api/v1/scheduled_event_rsvps/#{rsvp.id}",
        headers: auth_headers_for(parent, organization: organization)

      expect(response).to have_http_status(:no_content)
      expect(rsvp.reload).to be_deleted
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
