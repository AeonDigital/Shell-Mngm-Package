Shell-Mngm-Package
================================

> [Aeon Digital](http://www.aeondigital.com.br)  
> rianna@aeondigital.com.br

&nbsp;

> A lightweight utility toolset to bundle, validate, and dynamically deploy single-file shell script distributions.

&nbsp;

A pair of robust, production-ready shell utilities designed to streamline the lifecycle
of distributed shell scripts. The exporter scans source directory structures and
assets, strip-minifies code comments and spaces, and flattens dependencies into a
secure, single-file bundle with automatic header metadata injection. Its installation
counterpart automates remote environment provisioning, implements resilient HTTP/network
trapping via curl, handles directory traversal protection (`../`), and auto-unlocks
system execution flags natively.




&nbsp;
________________________________________________________________________________

## DOWNLOAD AND USE

To install or update both utilities instantly without manually handling parameters,
copy and execute the command below in your terminal. This one-liner pulls the installer,
provisions your native local user binary directory (`$XDG_BIN_HOME` or `~/.local/bin`),
deploys both tools into separate sandboxed directories, and sets up executable states
automatically:

```bash
# Download and install the package installer tool
curl -sSL "https://githubusercontent.com" | \
  bash -s -- \
  "https://githubusercontent.com" \
  "shell_package_installer" \
  "package_install" && \
\

# Download and install the package exporter tool
curl -sSL "https://githubusercontent.com" | \
  bash -s -- \
  "https://githubusercontent.com" \
  "shell_package_exporter" \
  "package_export"
```



### Manual Execution Examples

Once deployed, you can access the embedded manual guidelines for each script passing
standard help flags:

```bash
# Display the Single-File Exporter Manual
~/.local/bin/shell_package_exporter/package_export.sh --help

# Display the Automated Installer Manual
~/.local/bin/shell_package_installer/package_install.sh --help
```