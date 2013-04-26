source 'https://rubygems.org'
ruby '1.9.3'

# Specify your gem's dependencies in tent_admin.gemspec
gemspec

gem 'puma'

gem 'rack-putty', :git => 'git://github.com/tent/rack-putty.git', :branch => 'master'
gem 'tent-client', :git => 'git://github.com/tent/tent-client-ruby.git', :branch => '0.3'
gem 'hawk-auth', :git => 'git://github.com/tent/hawk-auth-ruby.git', :branch => 'master'
gem 'omniauth-tent', :git => 'git://github.com/tent/omniauth-tent.git', :branch => '0.3'
gem 'marbles-js', :git => 'git://github.com/jvatic/marbles-js.git', :branch => 'master'
gem 'icing', :git => 'git://github.com/tent/icing.git', :branch => 'master'
gem 'sequel-json', :git => 'git://github.com/tent/sequel-json.git', :branch => 'master'

group :development, :assets do
  gem 'asset_sync', :git => 'git://github.com/titanous/asset_sync.git', :branch => 'fix-mime'
  gem 'mime-types'
  gem 'yui-compressor'
end