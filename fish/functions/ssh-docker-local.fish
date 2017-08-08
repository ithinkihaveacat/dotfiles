# When configured via docker/Dockerfile
function ssh-docker-local
  ssh -i $HOME/.ssh/play_rsa -p 8022 mjs@127.0.0.1
end
