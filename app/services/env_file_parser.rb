class EnvFileParser
  def self.parse(content)
    new(content).parse
  end

  def initialize(content)
    @content = content.to_s
  end

  def parse
    Dotenv::Parser.call(@content)
  rescue Dotenv::FormatError => e
    raise ArgumentError, "Invalid .env content: #{e.message}"
  end
end
