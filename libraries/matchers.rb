if defined?(ChefSpec)
  def enable_runit_service(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :runit_service,
      :enable,
      resource_name
    )
  end

  def enable_web_app(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :web_app,
      :enable,
      resource_name
    )
  end
end
