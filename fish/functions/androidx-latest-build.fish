function androidx-latest-build -d "Returns buildId of latest androidx build, see https://androidx.dev/"
    curl -sS -D - -o /dev/null https://androidx.dev/snapshots/latest/artifacts | string match -g -r "^location: /snapshots/builds/(\d+)/artifacts"
end
