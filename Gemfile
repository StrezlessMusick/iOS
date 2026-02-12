source "https://rubygems.org"

gem "fastlane", ">= 2.211.0"
gem "xcov", ">= 1.9.0"
gem "fastlane-plugin-json"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
