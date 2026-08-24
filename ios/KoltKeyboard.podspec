Pod::Spec.new do |s|
  s.name           = 'KoltKeyboard'
  s.version        = '1.0.0'
  s.summary        = 'A sample project summary'
  s.description    = 'A sample project description'
  s.author         = ''
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = {
    :ios => '16.4',
    :tvos => '16.4'
  }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  # The Expo module must not compile the old standalone SwiftUI app under
  # ios/Sources. Only this bridge belongs in the host application's pod.
  s.source_files = "KoltKeyboardModule.swift"
end
