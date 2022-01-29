#

version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = "binlogik"
  spec.version       = version
  spec.authors       = ["Jon Bardin"]
  spec.email         = ["diclophis@gmail.com"]

  spec.summary       = %q{ruby based mysql binlog sidecar utility}
  spec.description   = %q{STUFF}
  spec.homepage      = "https://github.com/diclophis/binlogik"

  spec.license       = "BSD"

  spec.files         = Dir.glob("lib/**/*")
  spec.bindir        = ["bin"]
  spec.executables   = ["binlogik"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", "~> 2"
  spec.add_dependency "mysql2", "~> 0.5"
  spec.add_dependency "superconfig2"
end
