require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_autoloader_layout')
PuppetLint.configuration.send('disable_documentation')

task :r10k do
  sh "r10k -v INFO puppetfile install --moduledir puppet/modules --puppetfile puppet/Puppetfile"
end
