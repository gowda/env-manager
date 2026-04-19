require "rails_helper"

RSpec.describe EnvFileParser do
  it "parses quoted, escaped and multiline dotenv values" do
    content = <<~ENVFILE
      SIMPLE=value
      QUOTED="a b"
      ESCAPED="line1\\nline2"
      MULTILINE="line1
      line2"
    ENVFILE

    parsed = described_class.parse(content)

    expect(parsed).to eq(
      "SIMPLE" => "value",
      "QUOTED" => "a b",
      "ESCAPED" => "line1\\nline2",
      "MULTILINE" => "line1\nline2"
    )
  end

  it "preserves raw value when quote is unterminated" do
    parsed = described_class.parse("A=\"unterminated")

    expect(parsed).to eq("A" => "\"unterminated")
  end

  it "ignores blank lines and comments" do
    content = <<~ENVFILE
      # leading comment

      A=1

      # inline section comment
      B=2
    ENVFILE

    parsed = described_class.parse(content)

    expect(parsed).to eq(
      "A" => "1",
      "B" => "2"
    )
  end

  it "treats bare keys without assignment as empty values" do
    content = <<~ENVFILE
      A=1
      NOT_A_VALID_ENV_LINE
    ENVFILE

    parsed = described_class.parse(content)

    expect(parsed).to eq(
      "A" => "1",
      "NOT_A_VALID_ENV_LINE" => ""
    )
  end

  it "trims trailing whitespace for unquoted values" do
    content = <<~ENVFILE
      A=value
      B=value-with-space
    ENVFILE

    parsed = described_class.parse(content)

    expect(parsed).to eq(
      "A" => "value",
      "B" => "value-with-space"
    )
  end
end
