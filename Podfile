platform :macos, '10.15'
inhibit_all_warnings!

target 'serialtool' do
    
    project 'Serial', {
        'Debug' => :debug,
        'Release' => :release
    }
    use_frameworks!
    pod 'ArgumentParserKit', '~> 1.0.0'
    pod 'SerialPort', :path => '.'
end
