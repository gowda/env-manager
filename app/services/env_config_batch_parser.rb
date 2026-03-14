class EnvConfigBatchParser
  attr_reader :env_config, :raw_input, :errors

  def initialize(env_config:, raw_input:)
    @env_config = env_config
    @raw_input = raw_input.to_s
    @errors = []
  end

  def parse
    operations = []

    raw_input.each_line.with_index(1) do |line, line_no|
      stripped = line.strip
      next if stripped.empty?

      if stripped.start_with?("delete ")
        key = stripped.delete_prefix("delete ").strip
        operations << delete_operation(key, line_no)
        next
      end

      if stripped.start_with?("-")
        key = stripped.delete_prefix("-").strip
        operations << delete_operation(key, line_no)
        next
      end

      left, value = stripped.split("=", 2)
      if value.nil?
        @errors << "Line #{line_no}: missing '=' for upsert entry"
        next
      end

      key, value_type = parse_key_and_type(left)
      value_type ||= "single_line"

      if key.blank?
        @errors << "Line #{line_no}: key is required"
        next
      end

      unless EnvironmentVariable::VALUE_TYPES.include?(value_type)
        @errors << "Line #{line_no}: invalid value_type '#{value_type}'"
        next
      end

      if value.strip.empty?
        @errors << "Line #{line_no}: value cannot be blank"
        next
      end

      if value_type == "single_line" && value.match?(/[\r\n]/)
        @errors << "Line #{line_no}: single_line value must not include newline"
        next
      end

      operations << {
        line_no: line_no,
        op: "upsert",
        key: key,
        value_type: value_type,
        value: value
      }
    end

    operations
  end

  private

  def parse_key_and_type(left)
    key_part, type_part = left.split("|", 2)
    [key_part.to_s.strip, type_part.to_s.strip.presence]
  end

  def delete_operation(key, line_no)
    if key.blank?
      @errors << "Line #{line_no}: key is required for delete"
      return { line_no: line_no, op: "invalid" }
    end

    { line_no: line_no, op: "delete", key: key }
  end
end
