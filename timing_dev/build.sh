#!/usr/bin/env bash

# timing_dev/build.sh
# Get all files necessary to build the timing image. 
# Assumptions:
# - On SLAC AFS
# - 2 GB available space

release_site_template=RELEASE_SITE_template
temp_files_dir=temp_files
git_repos=/afs/slac/g/cd/swe/git/repos/package/epics
package_area=/afs/slac/g/lcls/package

# $1 is the EPICS base version
function base_version_in_files() {
    sed -i -e "s/*TAG_BASE_VERSION/$1/g" Dockerfile
    cp -f $release_site_template $temp_files_dir/modules/RELEASE_SITE
    sed -i -e "s/*TAG_BASE_VERSION/$1/g" $temp_files_dir/modules/RELEASE_SITE
}

# $1 is the EPICS base version to bring
function get_epics_base() {
    mkdir -p $temp_files_dir/base
    # Remove last portion of the version number and replace with the string
    # 'branch'. We are cloning the branch HEAD instead of a tag.
    base_branch=${base_version%?}branch
    git clone --branch $base_branch $git_repos/base/base.git $temp_files_dir/base/$1
    base_version_in_files $1
}

# $1 is the module name.
# $2 is the module version.
function add_module_to_dockerfile() {
    echo >> Dockerfile
    echo "## " $1 >> Dockerfile 
    echo "### " $2 >> Dockerfile
    echo ARG ${1^^}_MODULE_VERSION=$2 >> Dockerfile
    echo WORKDIR \${EPICS_MODULES} >> Dockerfile
    echo RUN mkdir -p $1/\${${1^^}_MODULE_VERSION} >> Dockerfile
    echo WORKDIR $1/\${${1^^}_MODULE_VERSION} >> Dockerfile
    echo COPY $temp_files_dir/modules/$1/\${${1^^}_MODULE_VERSION} . >> Dockerfile
    echo "#" Point to the re2c install in the system >> Dockerfile
    echo RUN if [ -f configure/CONFIG_SITE ]";" then sed -i -e "'s|^RE2C =.*|RE2C = /usr/bin/re2c|g'" configure/CONFIG_SITE";" fi"; \\" >> Dockerfile
    echo "#" Remove cross compilation >> Dockerfile
    echo "    "if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]";" then sed -i -e "'s|^PACKAGE_AREA=.*|PACKAGE_AREA=\${PACKAGE_SITE_TOP}|g'" configure/CONFIG_SITE.Common.rhel6-x86_64";" fi"; \\" >> Dockerfile
    echo "    "if [ -f configure/CONFIG_SITE ]";" then sed -i -e "'s|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g'" configure/CONFIG_SITE";" fi"; \\" >> Dockerfile
    echo "    "rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64"; \\" >> Dockerfile
    echo "    "make >> Dockerfile
}

# $1 is the module name.
# $2 is the module version.
function bring_module() {
    mkdir $temp_files_dir/modules/$1
    git clone --branch $2 $git_repos/modules/$1.git $temp_files_dir/modules/$1/$2
    add_module_to_dockerfile $1 $2
}

# No args
function get_epics() {
    mkdir -p $temp_files_dir/modules
    filename='epics-modules'

    # Reading each line with modules versions.
    while read line; do
	# Read last string after space. It must be in the format
	# <module name>/<version>
        version=${line##* }

	# Separates the module name from the version in an array
        tuplet=(${version//// })

	if [ ${tuplet[0]} == 'base' ]; then
            base_version=${tuplet[1]}

            # Bring EPICS base from AFS Git
	    get_epics_base $base_version
	else
	    # Bring the module from AFS Git
	    bring_module ${tuplet[0]} ${tuplet[1]}
	fi
    done < $filename
}

# No args
function get_packages() {
    filename='packages'

    # Reading each line with package versions.
    while read line; do
	echo Copying $line
	mkdir -p $temp_files_dir/packages/$line
	cp -Rn $package_area/$line/rhel6-x86_64 $temp_files_dir/packages/$line
    done < $filename
}

echo "Removing previous files."
rm -rf $temp_files_dir
rm Dockerfile

echo "Getting files."
cp Dockerfile_template_1 Dockerfile
get_packages
get_epics
cat Dockerfile_template_2 >> Dockerfile

echo "Ready. Run docker build."
