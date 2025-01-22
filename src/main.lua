local core = require('core')

function main()
  repeat wait(0) until isSampAvailable()

  core.start()

  print(HELLO_WORLD)
end
