class EnvFileParser
  LINE_PATTERN = /\A([A-Z][A-Z0-9_]*)=(.*)\z/

  def self.parse(content)
    new(content).parse
  end

  def initialize(content)
    @content = content.to_s
  end

  def parse
    items = {}

    @content.each_line.with_index(1) do |line, line_no|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?("#")

      match = LINE_PATTERN.match(stripped)
      raise ArgumentError, "Invalid .env line at #{line_no}: #{line.strip}" unless match

      items[match[1]] = match[2]
    end

    items
  end
end
