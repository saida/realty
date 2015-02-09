
excludes = [
  "/gems/ckeditor-",
  "/gems/jquery-ui-rails-",
  "/gems/turbolinks-"
]
Realty::Application.config.assets.paths.reject!{|t| excludes.any?{|r| r.is_a?(Regexp) ? r.match(t.to_s) : t.to_s.include?(r)}}
