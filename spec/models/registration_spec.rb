require "rails_helper"

RSpec.describe Registration do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:registration)).to be_valid
    end

    it "requires status" do
      expect(build(:registration, status: nil)).not_to be_valid
    end

    it "prevents duplicate user per league" do
      existing = create(:registration)
      duplicate = build(:registration, league: existing.league, user: existing.user)
      expect(duplicate).not_to be_valid
    end

    it "allows same user in different leagues" do
      user = create(:user, :child)
      league1 = create(:league)
      league2 = create(:league)
      create(:registration, user: user, league: league1)
      expect(build(:registration, user: user, league: league2)).to be_valid
    end
  end

  describe "enums" do
    it { expect(build(:registration, status: :pending)).to be_pending }
    it { expect(build(:registration, status: :confirmed)).to be_confirmed }
    it { expect(build(:registration, status: :waitlisted)).to be_waitlisted }
    it { expect(build(:registration, status: :canceled)).to be_canceled }
    it { expect(build(:registration, status: :not_selected)).to be_not_selected }
  end

  describe "status transitions" do
    let(:registration) { create(:registration, status: :pending) }

    it "#confirm! sets status to confirmed" do
      registration.confirm!
      expect(registration).to be_confirmed
    end

    it "#waitlist! sets status to waitlisted" do
      registration.waitlist!
      expect(registration).to be_waitlisted
    end

    it "#cancel! sets status to canceled" do
      registration.cancel!
      expect(registration).to be_canceled
    end
  end

  describe "soft delete" do
    it "allows re-registration after soft delete" do
      registration = create(:registration)
      registration.mark_as_deleted!
      new_reg = build(:registration, league: registration.league, user: registration.user)
      expect(new_reg).to be_valid
    end
  end
end
