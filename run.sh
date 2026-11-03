#!/bin/bash
# -*- sh-basic-offset: 4; sh-indentation: 4 -*-
# Bootstrap a CI environment for R

set -e
# Comment out this line for quieter output:
# Or ratherm set it for a lot noisier output
# set -x

# Where do we run? OS can be 'Linux' or 'Darwin', ARCH can be 'x86_64' or 'arm64'
OS=$(uname -s)
ARCH=$(uname -m)

# Release (used for rapt sources entry) (or use $(lsb_release -cs), but at the
# start we have not yet ensured it is installed)
if [[ -f /etc/os-release ]]; then
    RELEASE=$(awk -F= '/VERSION_CODENAME/ {print $2}' /etc/os-release)
else
    RELEASE="<unknown>"
fi

# Default CRAN repo (use the CDN) and R verssion
CRAN=${CRAN:-"https://cloud.r-project.org"}
RVER=${RVER:-"4.6.1"}

## Optional drat repos, unset by default
DRAT_REPOS=${DRAT_REPOS:-""}

## Optional BSPM or RAPT use, defaults to bspm
## These are here for backwards compatibility
USE_BSPM=${USE_BSPM:-"TRUE"}
USE_RAPT=${USE_RAPT:-"FALSE"}
## Use BACKEND=... to pick
## Note that is you run this via the r-ci action, you can pick this
## directly in the yaml code instead which is preferred, see
##   https://github.com/eddelbuettel/github-actions/tree/master/r-ci
BACKEND=${BACKEND:-"BSPM"}

## Default r2u host is r2u.stat.illinois.edu but as it blocks some
## IP addresses in the ranges used by GitHub Actions we also use fallback
R2U_PRIMARY="https://r2u.stat.illinois.edu/ubuntu"
R2U_SECONDARY="http://r2u.eddelbuettel.com"
R2U=${R2U:-${R2U_PRIMARY}}

## Optional additional PPAs, unset by default
ADDED_PPAS=${ADDED_PPAS:-""}

## Optional trimming of extra apt source list entry, defaults to true
TRIM_APT_SOURCES=${TRIM_APT_SOURCES:-"TRUE"}

## Optional setting of type argument in covr::coverage() call below, defaults to "tests"
COVERAGE_TYPE=${COVERAGE_TYPE:-"tests"}

## Let's see if the new runners with four virtual CPUs can be taken advantage of
MAKEFLAGS=${MAKEFLAGS:-"-j 4"}

## Install Fortran on macOS as well -- no longer by default
BOOTSTRAP_MACOS_FORTRAN=${BOOTSTRAP_MACOS_FORTRAN:-"TRUE"}
## Install OpenMP on macOS as well -- no longer by default
BOOTSTRAP_MACOS_OPENMP=${BOOTSTRAP_MACOS_OPENMP:-"TRUE"}
## Xcode selected after the macOS OpenMP install -- override for platforms needing a specific version
BOOTSTRAP_MACOS_XCODE=${BOOTSTRAP_MACOS_XCODE:-"/Applications/Xcode.app"}

R_BUILD_ARGS=${R_BUILD_ARGS-"--no-build-vignettes --no-manual"}
R_CHECK_ARGS=${R_CHECK_ARGS-"--no-vignettes --no-manual --as-cran"}
R_CHECK_INSTALL_ARGS=${R_CHECK_INSTALL_ARGS-"--install-args=--install-tests"}
_R_CHECK_TESTS_NLINES_=0

ShowBanner() {
    echo "r-ci: Portable CI for R at Travis, GitHub Actions, Azure, ..."
}

ShowUbuntuBanner() {
    echo "Current Ubuntu distribution: '$(lsb_release -ds)' aka '${RELEASE}'"
    extip=$(curl -s ipinfo.io/ip)
    echo "Running via external IP address ${extip}"
    webstatus=$(curl --head --silent --no-fail --output /dev/null --write-out "%{http_code}" https://r2u.stat.illinois.edu || true)
    if test "${webstatus}" = "200"; then
        echo "The r2u repository is reachable"
    else
        echo "::notice::The primary r2u repository is *not reachable* from ${extip}. Switching to secondary URL."
        R2U=${R2U_SECONDARY}
        ## Recording the offending IP and nothing else
        curl -s http://r2u.eddelbuettel.com/manual/bad_gha_ip?${extip}
    fi
}

ShowMacOSBanner() {
    echo "Current macOS versin: '$(sw_vers -productVersion)'"
}

Bootstrap() {
    ShowBanner
    SetRepos

    if [[ "Darwin" == "${OS}" ]]; then
        BootstrapMac
    elif [[ "Linux" == "${OS}" ]]; then
        ## This tests explicitly for a stamp, the r2u4ci container
        if ! (test -f /etc/r2u_ci); then
            BootstrapLinux
        fi
    else
        echo "Unknown OS: ${OS}"
        exit 1
    fi

    if ! (test -e .Rbuildignore && grep -q 'run.sh' .Rbuildignore); then
        echo '^run\.sh$' >> .Rbuildignore
        echo '^\.devcontainer' >> .Rbuildignore
    fi

    # Make sure unit test package (among testthat, tinytest, RUnit) installed
    EnsureUnittestRunner

    # Report version
    echo "::group::Show sessionInfo()"
    Rscript -e 'sessionInfo()'
    echo "::endgroup::"
}

SetRepos() {
    echo "local({" >> ~/.Rprofile
    echo "   r <- getOption(\"repos\");" >> ~/.Rprofile
    echo "   r[\"CRAN\"] <- \"${CRAN}\"" >> ~/.Rprofile
    for d in ${DRAT_REPOS}; do
        echo "   r[\"${d}\"] <- \"https://${d}.github.io/drat\"" >> ~/.Rprofile
    done
    echo "   options(repos=r)" >> ~/.Rprofile
    echo "})" >> ~/.Rprofile
}

InstallPandoc() {
    ## deprecated 2020-Sep
    echo "Deprecated"
}

BootstrapLinux() {
    ## Check for sudo and install if needed:
    ## - normal actions runs as runner (needs it)
    ## - container runs as root and needs it _because all the expressions below have it_
    ##   (we could, one presumes, add an 'empty' shell script named 'sudo' that runs '$@'...)
    if ! (test -x /usr/bin/sudo); then
        echo "::group::Adding sudo"
        apt update
        apt install --yes --no-install-recommends sudo
        echo "::endgroup::"
    fi

    ## Tell apt to try multiple times
    echo 'Acquire::Retries "3";' | sudo tee /etc/apt/apt.conf.d/91-retries.conf > /dev/null

    ## Check for lsb_release and install if needed
    if ! (test -x /usr/bin/lsb_release); then
        echo "::group::Adding lsb-release"
        sudo apt install --yes --no-install-recommends lsb-release
        echo "::endgroup::"
    fi

    ShowUbuntuBanner

    ## If opted in, trim apt sources
    if [[ "${TRIM_APT_SOURCES}" != "FALSE" ]]; then
        echo "::group::Adjust apt sources"
        sudo rm -vf /etc/apt/sources.list.d/*.list
        sudo rm -vf /etc/apt/sources.list.d/google*.sources
        test -f /etc/apt/apt-mirrors.txt && sudo sed -i -e 's/azure\.//' /etc/apt/apt-mirrors.txt
        ls -l /etc/apt/sources.list.d/
        echo "::endgroup::"
    fi

    ## from r2u setup script
    if ! (test -f /etc/apt/sources.list.d/r2u.sources); then
        ## Hotfix for key issue
        echo 'Acquire::AllowInsecureRepositories "true";' | sudo tee /etc/apt/apt.conf.d/90local-secure > /dev/null
        #sudo apt update --quiet --quiet

        #sudo apt update -qq && sudo apt install --quiet --quiet --quiet --yes --no-install-recommends wget ca-certificates dirmngr gnupg gpg-agent
        wget -q -O- https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc | \
            sudo tee -a /etc/apt/trusted.gpg.d/eddelbuettel.asc > /dev/null
        #echo "deb [arch=amd64,arm64] https://r2u.stat.illinois.edu/ubuntu ${RELEASE} main" | sudo tee -a /etc/apt/sources.list.d/cranapt.list > /dev/null
        cat <<EOF | sudo tee -a /etc/apt/sources.list.d/r2u.sources >/dev/null
Types: deb
URIs: ${R2U}
Suites: ${RELEASE}
Components: main
Architectures: amd64 arm64
Signed-By: /etc/apt/trusted.gpg.d/eddelbuettel.asc
EOF

        wget -q -O- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
            sudo tee -a /etc/apt/trusted.gpg.d/rutter.asc > /dev/null
        #echo "deb [arch=amd64,arm64] https://cloud.r-project.org/bin/linux/ubuntu ${RELEASE}-cran40/" | sudo tee -a /etc/apt/sources.list.d/cran_r.list > /dev/null
        cat <<EOF | sudo tee -a /etc/apt/sources.list.d/cran.sources >/dev/null
Types: deb
URIs: https://cloud.r-project.org/bin/linux/ubuntu
Suites: ${RELEASE}-cran40/
Components:
Architectures: amd64 arm64
Signed-By: /etc/apt/trusted.gpg.d/rutter.asc
EOF
    fi
    if ! (test -f /etc/apt/preferences.d/99r2u); then
        cat <<EOF | sudo tee -a /etc/apt/preferences.d/99cranapt > /dev/null
Package: *
Pin: release o=CRAN-Apt Project
Pin: release l=CRAN-Apt Packages
Pin-Priority: 700
EOF
    fi

    ## Added PPAs, if given
    if [[ "${ADDED_PPAS}" != "" ]]; then
        ## Check for add-apt-repository and install if needed, using a fudge around the (manual) tz config dialog
        echo "::group::Adding PPAs"
        if ! (test -x /usr/bin/add-apt-repository); then
            echo 12 > /tmp/input.txt
            echo 5 >> /tmp/input.txt
            sudo apt install --yes tzdata < /tmp/input.txt
            sudo apt install --yes --no-install-recommends software-properties-common
        fi
        for ppa in "${ADDED_PPAS}"; do
            sudo add-apt-repository -y "${ppa}"
        done

        # Update after adding all repositories.
        sudo apt update
        echo "::endgroup::"
    fi

    # Install an R development environment. qpdf is also needed for --as-cran checks.
    # May 2020: we also need devscripts for checkbashism
    # Sep 2020: add bspm and remotes
    if ! (test -f /usr/bin/R); then
        echo "::group::Adding R qpdf devscript r-cran-remotes"
        sudo apt update
        sudo apt install --yes --no-install-recommends r-base-dev r-recommended qpdf devscripts r-cran-remotes

        # Default to no recommends
        echo 'APT::Install-Recommends "false";' | sudo tee /etc/apt/apt.conf.d/90local-no-recommends > /dev/null

        # Change permissions for /usr/local/lib/R/site-library
        # This should really be via 'staff adduser travis staff'
        # but that may affect only the next shell
        sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library
        echo "::endgroup::"
    fi

    # Process options
    BootstrapLinuxOptions

    # Hotfix while R 4.6.* updates for the few critical packages are being made
    # cf https://github.com/eddelbuettel/R-4.6.0-binary-transition
    # sudo apt install --yes --allow-downgrades r-base-core=4.5.3-1.2404.0 r-base-dev=4.5.3-1.2404.0 r-recommended=4.5.3-1.2404.0
}

BootstrapLinuxOptions() {
    if [[ -n "$BOOTSTRAP_LATEX" ]]; then
        # We add a backports PPA for more recent TeX packages.
        # sudo add-apt-repository -y "ppa:texlive-backports/ppa"
        sudo apt-get install -y --no-install-recommends \
            texlive-base texlive-latex-base \
            texlive-fonts-recommended texlive-fonts-extra \
            texlive-extra-utils texlive-latex-recommended texlive-latex-extra \
            texinfo lmodern
        # no longer exists: texlive-generic-recommended
    fi

    echo "::group::Adding bspm or rapt"
    if [[ "${BACKEND}" == "BSPM" ]]; then
        echo "Selecting 'bspm'"
        USE_BSPM="TRUE"
        USE_RAPT="FALSE"
    elif [[ "${BACKEND}" == "RAPT" ]]; then
        echo "Selecting 'rapt'"
        USE_BSPM="FALSE"
        USE_RAPT="TRUE"
    else
        echo "*** Error: Unknown backend '$BACKEND'"
    fi
    if [[ "${USE_BSPM}" == "TRUE" ]]; then
        echo "Preparing 'bspm'"
        ## sudo Rscript --vanilla -e 'install.packages("bspm", repos="https://cran.r-project.org")'
        ## sudo Rscript --vanilla -e 'remotes::install_github("Enchufa2/bspm")'
        ## for now to get 0.4.0.1 with type="binary-source"
        ## curl -OLs https://eddelbuettel.github.io/r-ci/bspm_0.4.0.1.tar.gz && sudo R CMD INSTALL bspm_0.4.0.1.tar.gz
        ## 2023-02-20 for now stick with 0.3.10
        ## sudo Rscript --vanilla -e 'remotes::install_url("https://cloud.r-project.org/src/contrib/Archive/bspm/bspm_0.3.10.tar.gz")'
        ## 2023-03-17 back bspm now at 0.5.1
        sudo apt update
        sudo apt install --yes --no-install-recommends r-cran-bspm
        echo "options(bspm.sudo = TRUE)" | sudo tee --append /etc/R/Rprofile.site > /dev/null
        echo "suppressMessages(bspm::enable())" | sudo tee --append /etc/R/Rprofile.site > /dev/null
        echo "options(bspm.version.check=FALSE)" | sudo tee --append /etc/R/Rprofile.site > /dev/null
        #echo "options(bspm.sudo=TRUE)" | sudo tee --append /etc/R/Rprofile.site > /dev/null
    fi
    if [[ "${USE_RAPT}" == "TRUE" ]]; then
        echo "Preparing 'rapt'"
        sudo tee /etc/apt/sources.list.d/rapt.sources > /dev/null <<EOF
Types: deb
URIs: https://cornball-ai.github.io/rapt
Suites: ${RELEASE}
Components: main
Trusted: yes
Enabled: yes
EOF
        sudo apt update
        sudo apt install --yes --no-install-recommends rapt
        #wget https://eddelbuettel.github.io/r-ci/rapt/rapt_0.1.0-1_amd64.deb -O /tmp/rapt.deb
        #sudo dpkg --install /tmp/rapt.deb
        #rm /tmp/rapt.deb
        #sudo apt update --quiet --quiet --quiet > /dev/null
    fi
    echo "::endgroup::"

}

BootstrapMac() {
    ShowMacOSBanner
    echo "::group::Adding R binary"
    # Install from latest CRAN binary build for OS X (given ${ARCH} from 'uname -m')
    wget -q ${CRAN}/bin/macosx/sonoma-${ARCH}/base/R-${RVER}-${ARCH}.pkg -O /tmp/R-latest.pkg
    echo "Installing macOS binary package for R on ${ARCH}"
    sudo installer -pkg "/tmp/R-latest.pkg" -target /
    rm "/tmp/R-latest.pkg"
    echo "::endgroup::"

    echo "::group::Adding qpdf"
    # qpdf
    brew install qpdf
    echo "::endgroup::"

    echo "::group::Adding remotes"
    # remotes
    sudo Rscript -e 'install.packages("remotes")'
    echo "::endgroup::"

    # Process options
    BootstrapMacOptions
}

BootstrapMacOptions() {
    if [[ -n "$BOOTSTRAP_LATEX" ]]; then
        # TODO: Install MacTeX.pkg once there's enough disk space
        MACTEX=BasicTeX.pkg
        wget -q http://ctan.math.utah.edu/ctan/tex-archive/systems/mac/mactex/$MACTEX -O "/tmp/$MACTEX"

        echo "Installing OS X binary package for MacTeX"
        sudo installer -pkg "/tmp/$MACTEX" -target /
        rm "/tmp/$MACTEX"
        # We need a few more packages than the basic package provides; this
        # post saved me so much pain:
        #   https://stat.ethz.ch/pipermail/r-sig-mac/2010-May/007399.html
        sudo tlmgr update --self
        sudo tlmgr install inconsolata upquote courier courier-scaled helvetic
    fi

    ## See https://github.com/r-universe-org/actions/blob/v11/macos-prep/action.yml#L85-L91
    if [[ "$BOOTSTRAP_MACOS_FORTRAN" == "TRUE" ]]; then
        echo "::group::Adding Fortran"
        #wget -q https://mac.r-project.org/tools/gfortran-14.2-universal.pkg -O /tmp/gfortran.pkg
        wget -q https://github.com/R-macos/gcc-14-branch/releases/download/gcc-14.2-darwin-r2.1/gfortran-14.2-universal.pkg -O /tmp/gfortran.pkg
        echo "Installing macOS Fortran binary package for R on ${ARCH}"
        sudo installer -pkg "/tmp/gfortran.pkg" -target /
        rm "/tmp/gfortran.pkg"
        mkdir -p ~/.R
        echo "FLIBS = /opt/gfortran/lib/gcc/aarch64-apple-darwin20.0/14.2.0/libemutls_w.a /opt/gfortran/lib/gcc/aarch64-apple-darwin20.0/14.2.0/libheapt_w.a -L/Library/Frameworks/R.framework/Resources/lib -lgfortran.5 -lquadmath.0" > ~/.R/Makevars
        echo "::endgroup::"
    fi

    if [[ "$BOOTSTRAP_MACOS_OPENMP" == "TRUE" ]] && [[ "$GITHUB_ACTIONS" == "true" ]]; then
        echo "::group::Adding OpenMP"
        omptgz=openmp-17.0.6-darwin20-Release.tar.gz
        #wget -q https://mac.r-project.org/openmp/$omptgz -O /tmp/$omptgz
        wget -q https://eddelbuettel.github.io/r-ci/macos/$omptgz -O /tmp/$omptgz
        echo "Installing macOS OpenMP binary package"
        sudo tar fvxz /tmp/$omptgz -C /
        rm /tmp/$omptgz
        if [[ -n "$BOOTSTRAP_MACOS_XCODE" ]] && [[ -d "$BOOTSTRAP_MACOS_XCODE" ]]; then
            sudo xcode-select -s "$BOOTSTRAP_MACOS_XCODE"
        fi
        echo "MACOSX_DEPLOYMENT_TARGET=11.0" >> $GITHUB_ENV
        echo "  xcode is set: $(xcode-select --print-path)"
        echo "  using SDK: $(xcrun --show-sdk-version)"
    echo "::endgroup::"
    fi

}

EnsureDevtools() {
    ## deprecated 2020-Sep
    echo "Deprecated"
}

EnsureUnittestRunner() {
    if test -f DESCRIPTION; then
        echo "::group::Adding unit test runners"
        if [[ "Linux" == "${OS}" ]]; then
            sudo Rscript -e 'dcf <- read.dcf(file="DESCRIPTION")[1,]; if ("Suggests" %in% names(dcf)) { sug <- dcf[["Suggests"]]; pkg <- do.call(c, lapply(c("testthat", "tinytest", "RUnit"), function(p, sug) if (grepl(p, sug)) p else NULL, sug)); if (!is.null(pkg)) install.packages(pkg, type="binary-source") }'
        else
            sudo Rscript -e 'dcf <- read.dcf(file="DESCRIPTION")[1,]; if ("Suggests" %in% names(dcf)) { sug <- dcf[["Suggests"]]; pkg <- do.call(c, lapply(c("testthat", "tinytest", "RUnit"), function(p, sug) if (grepl(p, sug)) p else NULL, sug)); if (!is.null(pkg)) install.packages(pkg) }'
        fi
        echo "::endgroup::"
    fi
}

InstallIfNotYetInstalled() {
    res=$(Rscript -e 'if (requireNamespace(commandArgs(TRUE), quietly=TRUE)) cat("YES") else cat("NO")' "$1")
    if [[ "${res}" != "YES" ]]; then
        if [[ "Linux" == "${OS}" ]]; then
            sudo Rscript -e 'install.packages(commandArgs(TRUE), type="binary-source")' "$1"
        else
            sudo Rscript -e 'install.packages(commandArgs(TRUE))' "$1"
        fi
    fi
}

AptGetInstall() {
    if [[ "Linux" != "${OS}" ]]; then
        echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [[ "" == "$*" ]]; then
        echo "No arguments to aptget_install"
        exit 1
    fi

    echo "Installing apt package(s) $@"
    sudo apt --yes --no-install-recommends --allow-unauthenticated install "$@"
}

DpkgCurlInstall() {
    if [[ "Linux" != "${OS}" ]]; then
        echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [[ "" == "$*" ]]; then
        echo "No arguments to dpkgcurl_install"
        exit 1
    fi

    echo "Installing remote package(s) $@"
    for rf in "$@"; do
        curl -OL ${rf}
        f=$(basename ${rf})
        sudo dpkg -i ${f}
        rm -v ${f}
    done
}

RInstall() {
    if [[ "" == "$*" ]]; then
        echo "No arguments to r_install"
        exit 1
    fi

    echo "Installing R package(s): $@"
    if [[ "Linux" == "${OS}" ]]; then
        sudo Rscript -e 'install.packages(commandArgs(TRUE), type="binary-source")' "$@"
    else
        sudo Rscript -e 'install.packages(commandArgs(TRUE))' "$@"
    fi
}

BiocInstall() {
    if [[ "" == "$*" ]]; then
        echo "No arguments to bioc_install"
        exit 1
    fi

    echo "Installing R Bioconductor package(s): $@"
    Rscript -e 'if (!requireNamespace("BiocManager", quietly=TRUE)) install.packages("BiocManager")'
    Rscript -e "BiocManager::install(commandArgs(TRUE), update=FALSE)" "$@"
}

RBinaryInstall() {
    if [[ -z "$#" ]]; then
        echo "No arguments to r_binary_install"
        exit 1
    fi

    if [[ "Linux" != "${OS}" ]] || [[ -n "${FORCE_SOURCE_INSTALL}" ]]; then
        echo "Fallback: Installing from source"
        RInstall "$@"
        return
    fi

    echo "Installing *binary* R packages: $*"
    r_packages=$(echo $* | tr '[:upper:]' '[:lower:]')
    r_debs=$(for r_package in ${r_packages}; do echo -n "r-cran-${r_package} "; done)

    AptGetInstall ${r_debs}
}

InstallGithub() {
    #EnsureDevtools
    sudo Rscript -e 'remotes::install_github(commandArgs(TRUE))' "$@"
}

InstallDeps() {
    #EnsureDevtools
    sudo Rscript -e 'remotes::install_deps(".")'
}

InstallDepsAndSuggests() {
    sudo Rscript -e 'remotes::install_deps(".", dependencies=TRUE)'
}

InstallBiocDeps() {
    ## deprecated 2020-Sep
    echo "Deprecated"
}

DumpSysinfo() {
    echo "Dumping system information."
    R -e '.libPaths(); sessionInfo(); installed.packages()'
}

DumpLogsByExtension() {
    if [[ -z "$1" ]]; then
        echo "dump_logs_by_extension requires exactly one argument, got: $@"
        exit 1
    fi
    extension=$1
    shift
    package=$(find . -maxdepth 1 -name "*.Rcheck" -type d)
    if [[ ${#package[@]} -ne 1 ]]; then
        echo "Could not find package Rcheck directory, skipping log dump."
        exit 0
    fi
    for name in $(find "${package}" -type f -name "*${extension}"); do
        echo ">>> Filename: ${name} <<<"
        cat ${name}
    done
}

DumpLogs() {
    echo "Dumping test execution logs."
    DumpLogsByExtension "out"
    DumpLogsByExtension "log"
    DumpLogsByExtension "fail"
}

Coverage() {
    echo "Running Code Coverage analysis via the covr package"

    ## assumes that the Rutter PPAs are in fact known, which is a given here
    AptGetInstall r-cran-covr

    Rscript -e "covr::codecov(type = '${COVERAGE_TYPE}', quiet = FALSE)"
}

UpdatePackages() {
    echo "Updating Packages"
    Rscript -e 'update.packages(ask=FALSE)'
}

getR() {

    if [ ! -f /.dockerenv ]; then
        ## no container, just use R
        echo "R"
    elif [ -f /usr/local/bin/Rdevel ]; then
        ## in drd use Rdevel
        echo "Rdevel"
    else
        ## fallback
        echo "R"
    fi
}

RunTests() {
    # Respect R-devel if it is in the container
    R=$(getR)

    echo "Building with: ${R} CMD build ${R_BUILD_ARGS}"
    ${R} CMD build ${R_BUILD_ARGS} .
    # We want to grab the version we just built.
    FILE=$(ls -1t *.tar.gz | head -n 1)

    # Create binary package (currently Windows only)
    if [[ "${OS:0:5}" == "MINGW" ]]; then
        R_CHECK_INSTALL_ARGS=${R_CHECK_INSTALL_ARGS-"--install-args=\"--build --install-tests\""}
    fi

    echo "Testing with: ${R} CMD check \"${FILE}\" ${R_CHECK_ARGS} ${R_CHECK_INSTALL_ARGS}"
    _R_CHECK_CRAN_INCOMING_=${_R_CHECK_CRAN_INCOMING_:-FALSE}
    if [[ "$_R_CHECK_CRAN_INCOMING_" == "FALSE" ]]; then
        echo "(CRAN incoming checks are off)"
    fi
    _R_CHECK_CRAN_INCOMING_=${_R_CHECK_CRAN_INCOMING_} ${R} CMD check "${FILE}" ${R_CHECK_ARGS} ${R_CHECK_INSTALL_ARGS}

    if [[ -n "${WARNINGS_ARE_ERRORS}" ]]; then
        if DumpLogsByExtension "00check.log" | grep -q WARNING; then
            echo "Found warnings, treated as errors."
            echo "Clear or unset the WARNINGS_ARE_ERRORS environment variable to ignore warnings."
            exit 1
        fi
    fi
}

Retry() {
    ## deprecated 2026-Aug
    echo "Deprecated"
    exit 0

    if "$@"; then
        return 0
    fi
    for wait_time in 5 20 30 60; do
        echo "Command failed, retrying in ${wait_time} ..."
        sleep ${wait_time}
        if "$@"; then
            return 0
        fi
    done
    echo "Failed all retries!"
    exit 1
}

ShowHelpAndExit() {
    echo "Usage: run.sh COMMAND"
    echo "Derived from the venerable r-travis project, and still maintained lovingly by @eddelbuettel."
    echo "See https://eddelbuettel.github.io/r-ci for more."
    exit 0
}

COMMAND=$1
#echo "Running command: ${COMMAND}"
shift
case $COMMAND in
    ##
    ## Bootstrap a new core system
    "bootstrap")
        Bootstrap
        ;;
    ## Code coverage via covr.io
    "coverage")
        Coverage
        ;;
    ##
    ## Ensure devtools is loaded (implicitly called)
    ## (Deprecated Sep 2020)
    "install_devtools"|"devtools_install")
        EnsureDevtools
        ;;
    ##
    ## Install a binary deb package via apt-get
    "install_aptget"|"aptget_install")
        AptGetInstall "$@"
        ;;
    ##
    ## Install a binary deb package via a curl call and local dpkg -i
    "install_dpkgcurl"|"dpkgcurl_install")
        DpkgCurlInstall "$@"
        ;;
    ##
    ## Install an R dependency from CRAN
    "install_r"|"r_install")
        RInstall "$@"
        ;;
    ##
    ## Install an R dependency from Bioconductor
    "install_bioc"|"bioc_install")
        BiocInstall "$@"
        ;;
    ##
    ## Install an R dependency as a binary (via c2d4u PPA)
    "install_r_binary"|"r_binary_install")
        RBinaryInstall "$@"
        ;;
    ##
    ## Install a package from github sources
    "install_github"|"github_package")
        InstallGithub "$@"
        ;;
    ##
    ## Install package dependencies from CRAN
    "install_deps")
        InstallDeps
        ;;
    ##
    ## Install package dependencies and suggests from CRAN
    "install_all")
        InstallDepsAndSuggests
        ;;
    ##
    ## Install package dependencies from Bioconductor and CRAN (needs devtools)
    ## deprecated 2020-Sep
    "install_bioc_deps")
        InstallBiocDeps
        ;;
    ##
    ## Update packages
    "update_packages")
        UpdatePackages
        ;;
    ##
    ##
    ## Run the actual tests, ie R CMD check
    "run_tests")
        RunTests
        ;;
    ##
    ## Dump information about installed packages
    "dump_sysinfo")
        DumpSysinfo
        ;;
    ##
    ## Dump build or check logs
    "dump_logs")
        DumpLogs
        ;;
    ##
    ## Dump selected build or check logs
    "dump_logs_by_extension")
        DumpLogsByExtension "$@"
        ;;
    ##
    ## Help
    "help")
        ShowHelpAndExit
        ;;
esac
