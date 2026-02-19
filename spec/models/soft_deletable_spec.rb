require "rails_helper"

RSpec.describe SoftDeletable do
  let(:user) { create(:user) }

  describe "#mark_as_deleted!" do
    it "sets deleted_at timestamp" do
      freeze_time do
        user.mark_as_deleted!
        expect(user.deleted_at).to eq(Time.current)
      end
    end
  end

  describe "#restore!" do
    it "clears deleted_at timestamp" do
      user.mark_as_deleted!
      user.restore!
      expect(user.deleted_at).to be_nil
    end
  end

  describe "#deleted?" do
    it "returns true when deleted" do
      user.mark_as_deleted!
      expect(user.deleted?).to be true
    end

    it "returns false when not deleted" do
      expect(user.deleted?).to be false
    end
  end

  describe "scopes" do
    before do
      @active = create(:user)
      @deleted = create(:user)
      @deleted.mark_as_deleted!
    end

    it "default scope excludes deleted" do
      expect(User.all).to include(@active)
      expect(User.all).not_to include(@deleted)
    end

    it ".with_deleted includes all records" do
      expect(User.with_deleted).to include(@active, @deleted)
    end

    it ".deleted returns only deleted records" do
      expect(User.with_deleted.deleted).to include(@deleted)
      expect(User.with_deleted.deleted).not_to include(@active)
    end
  end
end
