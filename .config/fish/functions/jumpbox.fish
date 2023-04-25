function jumpbox --wraps='ssh -p 22255 collin@jumpbox.corp.reva.tech' --description 'alias jumpbox ssh -p 22255 collin@jumpbox.corp.reva.tech'
  ssh -p 22255 collin@jumpbox.corp.reva.tech $argv
        
end
