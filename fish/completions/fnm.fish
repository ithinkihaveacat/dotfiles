# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_fnm_global_optspecs
	string join \n node-dist-mirror= fnm-dir= multishell-path= log-level= arch= version-file-strategy= corepack-enabled resolve-engines= h/help V/version
end

function __fish_fnm_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_fnm_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_fnm_using_subcommand
	set -l cmd (__fish_fnm_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c fnm -n "__fish_fnm_needs_command" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_needs_command" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_needs_command" -l multishell-path -d 'Where the current node version link is stored. This value will be populated automatically by evaluating `fnm env` in your shell profile. Read more about it using `fnm help env`' -r -F
complete -c fnm -n "__fish_fnm_needs_command" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_needs_command" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_needs_command" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_needs_command" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_needs_command" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_needs_command" -s V -l version -d 'Print version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "list-remote" -d 'List all remote Node.js versions'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "ls-remote" -d 'List all remote Node.js versions'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "list" -d 'List all locally installed Node.js versions'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "ls" -d 'List all locally installed Node.js versions'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "install" -d 'Install a new Node.js version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "i" -d 'Install a new Node.js version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "use" -d 'Change Node.js version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "env" -d 'Print and set up required environment variables for fnm'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "completions" -d 'Print shell completions to stdout'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "alias" -d 'Alias a version to a common name'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "unalias" -d 'Remove an alias definition'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "default" -d 'Set a version as the default version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "current" -d 'Print the current Node.js version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "exec" -d 'Run a command within fnm context'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "uninstall" -d 'Uninstall a Node.js version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "uni" -d 'Uninstall a Node.js version'
complete -c fnm -n "__fish_fnm_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l filter -d 'Filter versions by a user-defined version or a semver range' -r
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l lts -d 'Show only LTS versions (optionally filter by LTS codename)' -r
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l sort -d 'Version sorting order' -r -f -a "{desc\t'Sort versions in descending order (latest to earliest)',asc\t'Sort versions in ascending order (earliest to latest)'}"
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l latest -d 'Only show the latest matching version'
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand list-remote" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l filter -d 'Filter versions by a user-defined version or a semver range' -r
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l lts -d 'Show only LTS versions (optionally filter by LTS codename)' -r
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l sort -d 'Version sorting order' -r -f -a "{desc\t'Sort versions in descending order (latest to earliest)',asc\t'Sort versions in ascending order (earliest to latest)'}"
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l latest -d 'Only show the latest matching version'
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand ls-remote" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand list" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand list" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand list" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand list" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand list" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand list" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand list" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand list" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand ls" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand ls" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand ls" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand ls" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand ls" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand ls" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand ls" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand ls" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand install" -l progress -d 'Show an interactive progress bar for the download status' -r -f -a "{auto\t'',never\t'',always\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand install" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand install" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand install" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand install" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand install" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand install" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand install" -l lts -d 'Install latest LTS'
complete -c fnm -n "__fish_fnm_using_subcommand install" -l latest -d 'Install latest version'
complete -c fnm -n "__fish_fnm_using_subcommand install" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand install" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand i" -l progress -d 'Show an interactive progress bar for the download status' -r -f -a "{auto\t'',never\t'',always\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand i" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand i" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand i" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand i" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand i" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand i" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand i" -l lts -d 'Install latest LTS'
complete -c fnm -n "__fish_fnm_using_subcommand i" -l latest -d 'Install latest version'
complete -c fnm -n "__fish_fnm_using_subcommand i" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand i" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand use" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand use" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand use" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand use" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand use" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand use" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand use" -l install-if-missing -d 'Install the version if it isn\'t installed yet'
complete -c fnm -n "__fish_fnm_using_subcommand use" -l silent-if-unchanged -d 'Don\'t output a message identifying the version being used if it will not change due to execution of this command'
complete -c fnm -n "__fish_fnm_using_subcommand use" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand use" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand env" -l shell -d 'The shell syntax to use. Infers when missing' -r -f -a "{bash\t'',zsh\t'',fish\t'',powershell\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand env" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand env" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand env" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand env" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand env" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand env" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand env" -l json -d 'Print JSON instead of shell commands'
complete -c fnm -n "__fish_fnm_using_subcommand env" -l multi -d 'Deprecated. This is the default now'
complete -c fnm -n "__fish_fnm_using_subcommand env" -l use-on-cd -d 'Print the script to change Node versions every directory change'
complete -c fnm -n "__fish_fnm_using_subcommand env" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand env" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l shell -d 'The shell syntax to use. Infers when missing' -r -f -a "{bash\t'',zsh\t'',fish\t'',powershell\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand completions" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand completions" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand alias" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand alias" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand alias" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand alias" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand alias" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand alias" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand alias" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand alias" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand unalias" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand default" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand default" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand default" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand default" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand default" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand default" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand default" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand default" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand current" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand current" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand current" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand current" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand current" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand current" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand current" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand current" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l using -d 'Either an explicit version, or a filename with the version written in it' -r
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l using-file -d 'Deprecated. This is the default now'
complete -c fnm -n "__fish_fnm_using_subcommand exec" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand exec" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand uninstall" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand uni" -l node-dist-mirror -d '<https://nodejs.org/dist/> mirror' -r
complete -c fnm -n "__fish_fnm_using_subcommand uni" -l fnm-dir -d 'The root directory of fnm installations' -r -F
complete -c fnm -n "__fish_fnm_using_subcommand uni" -l log-level -d 'The log level of fnm commands' -r -f -a "{quiet\t'',error\t'',info\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand uni" -l arch -d 'Override the architecture of the installed Node binary. Defaults to arch of fnm binary' -r
complete -c fnm -n "__fish_fnm_using_subcommand uni" -l version-file-strategy -d 'A strategy for how to resolve the Node version. Used whenever `fnm use` or `fnm install` is called without a version, or when `--use-on-cd` is configured on evaluation' -r -f -a "{local\t'Use the local version of Node defined within the current directory',recursive\t'Use the version of Node defined within the current directory and all parent directories'}"
complete -c fnm -n "__fish_fnm_using_subcommand uni" -l resolve-engines -d 'Resolve `engines.node` field in `package.json` whenever a `.node-version` or `.nvmrc` file is not present. This feature is enabled by default. To disable it, provide `--resolve-engines=false`.' -r -f -a "{true\t'',false\t''}"
complete -c fnm -n "__fish_fnm_using_subcommand uni" -l corepack-enabled -d 'Enable corepack support for each new installation. This will make fnm call `corepack enable` on every Node.js installation. For more information about corepack see <https://nodejs.org/api/corepack.html>'
complete -c fnm -n "__fish_fnm_using_subcommand uni" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "list-remote" -d 'List all remote Node.js versions'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "list" -d 'List all locally installed Node.js versions'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "install" -d 'Install a new Node.js version'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "use" -d 'Change Node.js version'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "env" -d 'Print and set up required environment variables for fnm'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "completions" -d 'Print shell completions to stdout'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "alias" -d 'Alias a version to a common name'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "unalias" -d 'Remove an alias definition'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "default" -d 'Set a version as the default version'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "current" -d 'Print the current Node.js version'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "exec" -d 'Run a command within fnm context'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "uninstall" -d 'Uninstall a Node.js version'
complete -c fnm -n "__fish_fnm_using_subcommand help; and not __fish_seen_subcommand_from list-remote list install use env completions alias unalias default current exec uninstall help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
