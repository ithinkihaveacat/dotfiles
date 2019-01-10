function docker-npx --description "Run npx in Docker container"
  # So, mounting the ~/.npm cache directory makes things slower...
  command docker run -it --rm -v "$PWD":/app:delegated -w /app node npx $argv
end
