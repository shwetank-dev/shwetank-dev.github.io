# frozen_string_literal: true

source "https://rubygems.org"

# Main Jekyll theme
gem "jekyll-theme-chirpy", "~> 7.2", group: :jekyll_plugins

# Required for GitHub Pages and modern Ruby
gem "webrick", "~> 1.7"

# Optional: for validating HTML during test
gem "html-proofer", "~> 5.0", group: :test

# Windows compatibility
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.2.0", platforms: [:mingw, :x64_mingw, :mswin]
