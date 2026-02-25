class Variable < ApplicationRecord
  self.inheritance_column = "inheritance_type"

  enum :type, { string: "string", number: "number", secure_string: "secure_string", multi_line_string: "multi_line_string" }, prefix: true
end
