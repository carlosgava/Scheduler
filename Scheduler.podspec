Pod::Spec.new do |s|
  s.name             = "Scheduler"
  s.version          = "1.0.0"
  s.license          = { :type => "MIT" }
  s.homepage         = "https://github.com/carlosgava/Scheduler"
  s.author           = { "Carlos Henrique Gava" => "carlos.gava@gmail.com" }
  s.summary          = "Agende uma tarefa de tempo no Swift usando uma API fluente"

  s.source           = { :git => "https://github.com/carlosgava/Scheduler.git", :tag => "#{s.version}" }
  s.source_files     = "Sources/Scheduler/*.swift"
  
  s.swift_version    = "5.0"

  s.ios.deployment_target = "9.0"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"
end

