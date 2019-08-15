Pod::Spec.new do |s|
  s.name         = "GCAppirater"
  s.version      = "3.2.2"
  s.summary      = "GC fork of Appirater."
  s.homepage     = "https://github.com/gamechanger/gcappirater.git"
  s.author       = { "Brian Bernberg" => "brian@gc.com" }
  s.source       = { :git => "https://github.com/gamechanger/gcappirater.git", :tag => "3.2.1" }
  s.source_files = "Pod/Classes/**/*"
  s.frameworks = 'CFNetwork', 'SystemConfiguration'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '10.0'
end
