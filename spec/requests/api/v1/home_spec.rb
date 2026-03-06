require "rails_helper"

RSpec.describe "Api::V1::Home" do
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let(:parent) { create(:user) }
  let(:child) { create(:user, :child, gender: :male, grade_level: 5) }
  let(:family) { create(:family) }

  before do
    create(:organization_membership, user: parent, organization: organization)
    create(:family_membership, family: family, user: parent, role: :parent)
    create(:family_membership, family: family, user: child, role: :child)
  end

  describe "GET /api/v1/home" do
    it "returns empty arrays for a user with no registrations or open leagues" do
      season = create(:season, activity_type: activity_type,
        registration_start_at: 2.months.ago, registration_end_at: 1.month.ago)
      create(:league, season: season, min_grade: 5, max_grade: 6, gender: :male)

      get "/api/v1/home", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_data["activeRegistrations"]).to eq([])
      expect(parsed_data["openLeagues"]).to eq([])
    end

    it "returns 401 without authentication" do
      get "/api/v1/home"

      expect(response).to have_http_status(:unauthorized)
    end

    context "active registrations" do
      let(:season) do
        create(:season, activity_type: activity_type,
          start_date: 1.month.ago.to_date, end_date: 3.months.from_now.to_date)
      end
      let(:league) { create(:league, season: season, min_grade: 5, max_grade: 6, gender: :male) }

      it "includes active registrations for the user's children" do
        registration = create(:registration, league: league, user: child, registered_by: parent, status: :confirmed)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(response).to have_http_status(:ok)
        regs = parsed_data["activeRegistrations"]
        expect(regs.length).to eq(1)
        expect(regs[0]["id"]).to eq(registration.id)
        expect(regs[0]["status"]).to eq("confirmed")
        expect(regs[0]["user"]["id"]).to eq(child.id)
        expect(regs[0]["user"]["fullName"]).to eq(child.full_name)
        expect(regs[0]["league"]["id"]).to eq(league.id)
        expect(regs[0]["season"]["name"]).to eq(season.name)
        expect(regs[0]["activityType"]["name"]).to eq(activity_type.name)
        expect(regs[0]["organization"]["name"]).to eq(organization.name)
      end

      it "includes team info when the child is on a team" do
        team = create(:team, league: league, name: "A Team")
        create(:registration, league: league, user: child, registered_by: parent, status: :confirmed)
        create(:team_membership, team: team, user: child, role: :player)

        get "/api/v1/home", headers: auth_headers_for(parent)

        regs = parsed_data["activeRegistrations"]
        expect(regs[0]["team"]["name"]).to eq("A Team")
        expect(regs[0]["team"]["role"]).to eq("player")
      end

      it "excludes canceled registrations" do
        create(:registration, league: league, user: child, registered_by: parent, status: :canceled)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["activeRegistrations"]).to be_empty
      end

      it "excludes not_selected registrations" do
        create(:registration, league: league, user: child, registered_by: parent, status: :not_selected)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["activeRegistrations"]).to be_empty
      end

      it "excludes registrations for past seasons" do
        past_season = create(:season, activity_type: activity_type,
          start_date: 6.months.ago.to_date, end_date: 2.months.ago.to_date)
        past_league = create(:league, season: past_season)
        create(:registration, league: past_league, user: child, registered_by: parent, status: :confirmed)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["activeRegistrations"]).to be_empty
      end

      it "includes the parent's own registrations for adult leagues" do
        create(:registration, league: league, user: parent, registered_by: parent, status: :pending)

        get "/api/v1/home", headers: auth_headers_for(parent)

        regs = parsed_data["activeRegistrations"]
        expect(regs.length).to eq(1)
        expect(regs[0]["user"]["id"]).to eq(parent.id)
      end
    end

    context "open leagues" do
      let(:season) do
        create(:season, activity_type: activity_type,
          registration_start_at: 1.week.ago, registration_end_at: 1.month.from_now)
      end

      it "returns leagues with open registration where a child is eligible" do
        league = create(:league, season: season, min_grade: 4, max_grade: 6, gender: :male)

        get "/api/v1/home", headers: auth_headers_for(parent)

        leagues = parsed_data["openLeagues"]
        expect(leagues.length).to eq(1)
        expect(leagues[0]["id"]).to eq(league.id)
        expect(leagues[0]["name"]).to eq(league.name)
        expect(leagues[0]["season"]["name"]).to eq(season.name)
        expect(leagues[0]["organization"]["name"]).to eq(organization.name)
        expect(leagues[0]["eligibleMembers"].length).to eq(1)
        expect(leagues[0]["eligibleMembers"][0]["id"]).to eq(child.id)
      end

      it "excludes leagues where no child is eligible by grade" do
        create(:league, season: season, min_grade: 7, max_grade: 8, gender: :male)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["openLeagues"]).to be_empty
      end

      it "excludes leagues where no child is eligible by gender" do
        create(:league, season: season, min_grade: 4, max_grade: 6, gender: :female)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["openLeagues"]).to be_empty
      end

      it "includes co-ed leagues" do
        league = create(:league, :coed, season: season, min_grade: 4, max_grade: 6)

        get "/api/v1/home", headers: auth_headers_for(parent)

        leagues = parsed_data["openLeagues"]
        expect(leagues.length).to eq(1)
        expect(leagues[0]["id"]).to eq(league.id)
      end

      it "excludes leagues where the child is already registered" do
        league = create(:league, season: season, min_grade: 4, max_grade: 6, gender: :male)
        create(:registration, league: league, user: child, registered_by: parent, status: :pending)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["openLeagues"]).to be_empty
      end

      it "still shows leagues where a canceled child can re-register" do
        league = create(:league, season: season, min_grade: 4, max_grade: 6, gender: :male)
        create(:registration, league: league, user: child, registered_by: parent, status: :canceled)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["openLeagues"].length).to eq(1)
      end

      it "excludes leagues from organizations the user doesn't belong to" do
        other_org = create(:organization)
        other_at = create(:activity_type, organization: other_org)
        other_season = create(:season, activity_type: other_at,
          registration_start_at: 1.week.ago, registration_end_at: 1.month.from_now)
        create(:league, season: other_season, min_grade: 4, max_grade: 6, gender: :male)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["openLeagues"]).to be_empty
      end

      it "excludes leagues where registration is closed" do
        closed_season = create(:season, activity_type: activity_type,
          registration_start_at: 2.months.ago, registration_end_at: 1.week.ago)
        create(:league, season: closed_season, min_grade: 4, max_grade: 6, gender: :male)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["openLeagues"]).to be_empty
      end

      it "shows full leagues with full flag" do
        league = create(:league, season: season, min_grade: 4, max_grade: 6, gender: :male, capacity: 1)
        other_child = create(:user, :child)
        create(:registration, league: league, user: other_child, registered_by: create(:user), status: :confirmed)

        get "/api/v1/home", headers: auth_headers_for(parent)

        leagues = parsed_data["openLeagues"]
        expect(leagues.length).to eq(1)
        expect(leagues[0]["full"]).to be true
      end
    end

    context "cross-organization" do
      it "includes data from multiple organizations" do
        org2 = create(:organization)
        at2 = create(:activity_type, organization: org2)
        season1 = create(:season, activity_type: activity_type,
          start_date: 1.month.ago.to_date, end_date: 3.months.from_now.to_date)
        season2 = create(:season, activity_type: at2,
          start_date: 1.month.ago.to_date, end_date: 3.months.from_now.to_date,
          registration_start_at: 1.week.ago, registration_end_at: 1.month.from_now)

        create(:organization_membership, user: parent, organization: org2)
        league1 = create(:league, season: season1, min_grade: 5, max_grade: 6, gender: :male)
        league2 = create(:league, season: season2, min_grade: 4, max_grade: 6, gender: :male)

        create(:registration, league: league1, user: child, registered_by: parent, status: :confirmed)

        get "/api/v1/home", headers: auth_headers_for(parent)

        expect(parsed_data["activeRegistrations"].length).to eq(1)
        expect(parsed_data["activeRegistrations"][0]["organization"]["id"]).to eq(organization.id)

        expect(parsed_data["openLeagues"].length).to eq(1)
        expect(parsed_data["openLeagues"][0]["organization"]["id"]).to eq(org2.id)
      end
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end

  def parsed_data
    parsed_body["data"]
  end
end
