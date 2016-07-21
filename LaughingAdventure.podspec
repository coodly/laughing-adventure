Pod::Spec.new do |s|
  s.name = 'LaughingAdventure'
  s.version = '0.3.0'
  s.license = 'Apache 2'
  s.summary = 'Common Swift code used in Coodly'
  s.homepage = 'https://github.com/coodly/laughing-adventure'
  s.authors = { 'Jaanus Siim' => 'jaanus@coodly.com' }
  s.source = { :git => 'git@github.com:coodly/laughing-adventure.git', :tag => s.version }
  s.default_subspec = 'Core'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'

  s.subspec 'Core' do |core|
    core.source_files = 'Source/*/*.swift'
  end
  
  s.subspec 'Logging' do |log|
  	log.source_files = "Source/Log"
  end

  s.subspec 'Purchase' do |purchase|
    purchase.dependency "LaughingAdventure/Logging"
    purchase.source_files = "Source/Purchase"
    purchase.frameworks = 'StoreKit'
  end

  s.subspec 'Feedback' do |feedback|
    feedback.source_files = "Source/Feedback"
  end

  s.subspec 'CoreData' do |model|
    model.dependency "LaughingAdventure/Logging"
    model.source_files = 'Source/CoreData'
    model.frameworks = 'CoreData'
  end
  
  s.requires_arc = true
end
