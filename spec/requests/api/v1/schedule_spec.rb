require "rails_helper"

RSpec.describe "Api::V1::Schedule" do
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let(:season) { create(:season, activity_type: activity_type) }
  let(:league) { create(:league, season: season) }
  let(:team) { create(:team, league: league) }

  let(:parent) { create(:user) }
  let(:child) { create(:user, :child) }
  let(:family) { create(:family) }

  before do
    create(:organization_membership, user: parent, organization: organization)
    create(:family_membership, family: family, user: parent, role: :parent)
    create(:family_membership, family: family, user: child, role: :child)
  end

  describe "GET /api/v1/schedule" do
    it "returns 401 without authentication" do
      get "/api/v1/schedule"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns empty occurrences when the family is on no teams" do
      get "/api/v1/schedule", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_data["occurrences"]).to eq([])
    end

    it "returns occurrences for a child's team with participant attribution" do
      create(:team_membership, team: team, user: child, role: :player)
      event = create(:scheduled_event, schedulable: team,
        start_at: 2.days.from_now.change(hour: 19), end_at: 2.days.from_now.change(hour: 20))

      get "/api/v1/schedule", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      occurrences = parsed_data["occurrences"]
      expect(occurrences.length).to eq(1)

      occ = occurrences[0]
      expect(occ["eventId"]).to eq(event.id)
      expect(occ["title"]).to eq(event.title)
      expect(occ["team"]["id"]).to eq(team.id)
      expect(occ["organization"]["name"]).to eq(organization.name)
      expect(occ["cancelled"]).to eq(false)

      participant_ids = occ["participants"].map { |p| p["id"] }
      expect(participant_ids).to contain_exactly(child.id)
    end

    it "includes the family's rsvps on occurrences" do
      create(:team_membership, team: team, user: child, role: :player)
      event = create(:scheduled_event, schedulable: team, rsvp_mode: :full,
        start_at: 2.days.from_now.change(hour: 19), end_at: 2.days.from_now.change(hour: 20))
      rsvp = create(:scheduled_event_rsvp, scheduled_event: event, user: child,
        occurrence_start_at: event.start_at, response: :yes, responded_by: parent)

      get "/api/v1/schedule", headers: auth_headers_for(parent)

      occ = parsed_data["occurrences"][0]
      participant = occ["participants"].find { |p| p["id"] == child.id }
      expect(participant["rsvp"]).to eq({ "id" => rsvp.id, "response" => "yes" })
    end

    it "respects from/to params" do
      create(:team_membership, team: team, user: child, role: :player)
      create(:scheduled_event, schedulable: team,
        start_at: 10.days.from_now.change(hour: 19), end_at: 10.days.from_now.change(hour: 20))

      get "/api/v1/schedule",
        params: { from: 1.day.from_now.iso8601, to: 5.days.from_now.iso8601 },
        headers: auth_headers_for(parent)

      expect(parsed_data["occurrences"]).to eq([])
    end

    it "does not include teams from other families" do
      other_child = create(:user, :child)
      create(:team_membership, team: team, user: other_child, role: :player)
      create(:scheduled_event, schedulable: team,
        start_at: 2.days.from_now.change(hour: 19), end_at: 2.days.from_now.change(hour: 20))

      get "/api/v1/schedule", headers: auth_headers_for(parent)

      expect(parsed_data["occurrences"]).to eq([])
    end
  end

  def parsed_body
    JSON.parse(response.body)
  end

  def parsed_data
    parsed_body["data"]
  end
end
