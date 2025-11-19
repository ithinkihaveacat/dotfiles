# When configured via docker/Dockerfile
function ssh-docker-remote
    # TODO Copy ssh key to ~/iCloud
    ssh -i (docker-machine inspect -f "{{.HostOptions.AuthOptions.StorePath}}")/id_rsa -p 80 mjs@(docker-machine ip)
end
