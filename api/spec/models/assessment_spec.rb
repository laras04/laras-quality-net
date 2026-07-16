require "rails_helper"

RSpec.describe Assessment, type: :model do
  it "is invalid without any assessment skills" do
    Current.tenant_id = 1

    assessment = Assessment.new(
      name: "Backend Engineer",
      time_limit_min: 45,
      language: "en",
      created_by: 1
    )

    expect(assessment.valid?).to eq(false)
  end
end