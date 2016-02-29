Pod::Spec.new do |s|
  s.name         = "GCAppirater"
  s.version      = "3.0.6"
  s.summary      = "GC fork of Appirater."
  s.homepage     = "https://github.com/gamechanger/gcappirater.git"
  s.author       = { "Brian Bernberg" => "brian@gc.com" }
  s.source       = { :git => "https://github.com/gamechanger/gcappirater.git", :tag => "3.0.6" }
  s.source_files = "*.{h,m}"
  s.frameworks = 'CFNetwork', 'SystemConfiguration'
  s.license = { :type => 'MIT', :type => 'LICENSE' }
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
end
