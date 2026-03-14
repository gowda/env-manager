ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

if Dir.exist?(File.expand_path("../node_modules", __dir__)) && ARGV.include?("assets:precompile")
  ENV["SKIP_YARN_INSTALL"] ||= "1"
end

require "bundler/setup"
require "bootsnap/setup"
