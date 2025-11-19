function pandoc-install-latest -d "Install latest version of pandoc"
    set -l URL (curl -sSL https://api.github.com/repos/jgm/pandoc/releases | jq -r '.[0].assets | .[].browser_download_url' | grep (uname -m)-macOS.pkg)
    echo "Installing $URL..."
    sudo installer -verbose -pkg (curl -sSL $URL | psub -s .pkg) -target /
end
