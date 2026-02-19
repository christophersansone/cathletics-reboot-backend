require "rails_helper"

RSpec.describe Organization do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:organization)).to be_valid
    end

    it "requires name" do
      expect(build(:organization, name: nil, slug: "test")).not_to be_valid
    end

    it "requires slug" do
      expect(build(:organization, name: nil, slug: nil)).not_to be_valid
    end

    it "enforces unique slug among non-deleted records" do
      create(:organization, slug: "st-marys")
      expect(build(:organization, slug: "st-marys")).not_to be_valid
    end

    it "allows reuse of slug after soft delete" do
      org = create(:organization, slug: "st-marys")
      org.mark_as_deleted!
      expect(build(:organization, slug: "st-marys")).to be_valid
    end

    it "rejects slugs with invalid characters" do
      expect(build(:organization, slug: "St Mary's")).not_to be_valid
      expect(build(:organization, slug: "has spaces")).not_to be_valid
      expect(build(:organization, slug: "UPPERCASE")).not_to be_valid
    end

    it "accepts valid slug formats" do
      expect(build(:organization, slug: "st-marys-academy")).to be_valid
      expect(build(:organization, slug: "school123")).to be_valid
    end
  end

  describe "auto slug generation" do
    it "generates slug from name when blank" do
      org = build(:organization, name: "St. Mary's Academy", slug: nil)
      org.valid?
      expect(org.slug).to eq("st-mary-s-academy")
    end

    it "does not overwrite an existing slug" do
      org = build(:organization, name: "St. Mary's Academy", slug: "custom-slug")
      org.valid?
      expect(org.slug).to eq("custom-slug")
    end
  end
end
