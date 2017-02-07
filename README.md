# Storm Debian Packaging

[![Build Status](https://travis-ci.org/pershyn/storm-debian-packaging.svg?branch=master)](https://travis-ci.org/pershyn/storm-debian-packaging)

Debian packaging for [Apache Storm](http://storm.apache.org) distributed
realtime computation system.

The goal of this project is to provide a flexible tool to build a debian package,
that follows debian standards and uses default configs, supplied with storm release.
Packaged storm can be used as easy as storm-zip unpacked elsewhere, and, at the same time,
provides a flexibility to configure it for reliable and convenient long-term
high-load production use.

Storm provides several services (nimbus, supervisor, drpc, ...).
This project provides separate packages for each service with corresponding systemd unit files.

Previously init scripts, upstart conf and runit files were provided.
Now only systemd is supported. See History section below for details.

See `./STORM_VERSION` file for supported storm version.

See `./sample-layout/` for example of packages content.

## Compatibility:

* This packages are intended to be used against Debian Jessie. Presumably it can be ran on any other debian-based distribution, because relies only on LSB. It has also upstart's conf files.
* There are previous versions (up to 0.9.1) built with FPM [here](https://github.com/pershyn/storm-deb-packaging). See also tags/branches and forks for different version of storm.

## Building a package

### Step 1. Prepare repository and check version of a package

1. Clone the repository.
2. Edit the `apache-storm/debian/changelog` to set packaging version/maintainer to your preferred values, so you get contacted if other people will use the package compiled by you.
3. Make sure you have desired version specified in `./STORM_VERSION` file and in `apache-storm/debian/changelog`.

### Step 2. Build a package
#### Build a package using docker (recommended)

In case you don't have debian running locally, docker container can be used.
For that `docker` and `make` should be installed in your system.

Run `make docker_package`, and the packages going to be built.

#### Build a package in native debian-based environment

1. Install necessary dependencies (see `Dockerfile` or `build.sh`).
2. Call `make orig`, this will download and prepare the upstream tarball.
In case you want to build `SNAPSHOT` or modified storm version - follow the instructions in next paragraph.
2. Run the `build.sh`. It will go to the nested `apache-storm` folder, that contains `debian` and execute the command to build package. The packages will be created in project root folder.
3. [Optional] After you have built a package and want to take a look at its content, run the next command to display package layout. Pass-in your package name and version:
```
$ dpkg -c ./storm_*_all.deb
```
The sample layouts for default version can be found in the [sample-layout](sample-layout) folder in repository.
4. [Optional] Cleanup the file tree.
```
ch ./apache-storm
dpkg-buildpackage -rfakeroot -Tclean
```

#### Build package in Vagrant

Vagrant can be used to automatically provision the machine to build
the script.

```bash
# prepare upstream tarball
make orig

# prepare and enter vm (debian)
vagrant up debian
vagrant ssh debian
# to build in ubuntu use `vagrant up ubuntu && vagrant ssh ubuntu`

cd /vagrant

# then run
sudo ./build.sh
```

Probably the other debian-based distribution can be used as well. See `./Vagrantfile`.

#### Build a package for SNAPSHOT version of storm.

Follow instructions in [storm/DEVELOPER.md](https://github.com/apache/storm/blob/master/DEVELOPER.md#packaging) to create a storm distribution.

    # First, build the code.
    # You may skip tests with `-DskipTests=true` to save time
    $ mvn clean install

    # Create the binary distribution.
    $ cd storm-dist/binary && mvn package

Then manually copy `storm-dist/binary/target/apache-storm-<version>.zip` to `downloads` and edit the `STORM_VERSION` and `debian/changelog` files to use the version as in this zip.

The proceed as with normal package, described above.

## Using a package:

According to [official storm guide](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster)
you have to have next things installed:
- Java 6. But, according to [recent info](https://www.mail-archive.com/user@storm.incubator.apache.org/msg03230.html), storm-0.9.x works perfectly with java 1.6, 1.7 and 1.8. Also both openjdk and oracle jdk are supported. This package is build with java 7.
- Python 2.6.6 - It may work also with other version, however this one claimed to be tested.

During the installation storm package also creates or enables existing storm user.

1. After you install a package - edit the `/etc/storm/storm.yaml` to specify nimbus and zookeeper path.
2. Start desired storm service with corresponding command. For example:
```
systemctl start storm-nimbus
systemctl start storm-supervisor
systemctl start storm-ui
systemctl start storm-drpc
systemctl start storm-logviewer
```
3. Enable those that you need to start automatically on system restart.
```
systemctl enable storm-nimbus
...
```
NOTE: the autorestart is configured in `*.service` unit file.
When crashed or killed, the services are going to be started again by systemd.
(Earlier that was done with `runit`).
4. Configure storm the way you need using `/etc/storm/storm_env.ini`.
5. Set limits in `/etc/security/limits.conf` (instead of using ulimit in /etc/default/storm).
```
# /etc/security/limits.conf
#
#Each line describes a limit for a user in the form:
#
#<domain>        <type>  <item>  <value>
#
#Where:
#<domain> can be:
#        - a user name
#        - a group name, with @group syntax
#        - the wildcard *, for default entry
#        - the wildcard %, can be also used with %group syntax,
#                 for maxlogin limit
#        - NOTE: group and wildcard limits are not applied to root.
#          To apply a limit to the root user, <domain> must be
#          the literal username root.
#
#<type> can have the two values:
#        - "soft" for enforcing the soft limits
#        - "hard" for enforcing hard limits
#
#<item> can be one of the following:
#        - core - limits the core file size (KB)
#        - data - max data size (KB)
#        - fsize - maximum filesize (KB)
#        - memlock - max locked-in-memory address space (KB)
#        - nofile - max number of open files
#        - rss - max resident set size (KB)
#        - stack - max stack size (KB)
#        - cpu - max CPU time (MIN)
#        - nproc - max number of processes
#        - as - address space limit (KB)
#        - maxlogins - max number of logins for this user
#        - maxsyslogins - max number of logins on the system
#        - priority - the priority to run user process with
#        - locks - max number of file locks the user can hold
#        - sigpending - max number of pending signals
#        - msgqueue - max memory used by POSIX message queues (bytes)
#        - nice - max nice priority allowed to raise to values: [-20, 19]
#        - rtprio - max realtime priority
#        - chroot - change root to directory (Debian-specific)
#
#<domain>      <type>  <item>         <value>
#

#*               soft    core            0
#root            hard    core            100000
#*               hard    rss             10000
#@student        hard    nproc           20
#@faculty        soft    nproc           20
#@faculty        hard    nproc           50
#ftp             hard    nproc           0
#ftp             -       chroot          /ftp
#@student        -       maxlogins       4

storm		hard	nofile		15000

# End of file
```
At some point, it is a good idea to use software configuration management tools to manage configuration of storm clusters. Checkout [saltstack](http://www.saltstack.com/), [chef](http://www.getchef.com/chef/), [puppet](https://puppetlabs.com/), [ansible](http://www.ansible.com/home).

## Details:

### $STORM_HOME, storm user home, and storm.local.dir.

Basically there are 2 folders (except configs, logs and init scripts):

- `$STORM_HOME` - created by package, stores all the libs and storm executables in `lib` and `bin` subfolders
- `storm.local.dir` - should be created by user and mentioned in storm.yaml, by default `§STORM_HOME/storm-local` is used.

Checking the history of [this fpm-project](https://github.com/pershyn/storm-deb-packaging), initially `$STORM_HOME` was `/opt/storm`.
Then some of the forks used `/usr/lib/storm`,
then original maintaner used `/var/lib/storm`,
and another forks moved to use `/opt/storm`...

So, there was a bit of a chaos.

Storm distribution deviate from debian packaging conventions,
(like separating libs, and executables),
so all the stuff that has to do something with storm goes to one `$STORM_HOME` folder.

The dilemma is how to organize a package, due to different perception by admins
and storm developers:

```
  |                   | ADMINS (Debian)       | DEVELOPERS
  -------------------------------------------------------------
  | Binary files      | /usr/bin/*            | $STORM_HOME/bin/*
  | Librariers        | /usr/lib/storm        | $STORM_HOME/lib/*
  | Configs           | /etc/storm/           | $STORM_HOME/conf/*
  | Logback config    | /etc/storm/logback.xml| $STORM_HOME/logback/cluster.xml
  | Logs              | /var/log/storm        | $STORM_HOME/logs/*
  | Supervisors       | /etc/init.d/*         | N/A
  | storm.local.dir   | /var/lib/storm/*      | ? (e.g. /mnt/storm, see Links)

```
Also, there are 2 concepts - the software could be packaged or not-packaged.

There is also [Filesystem Hierarchy Standard aka FHS](http://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)
([here](http://www.pathname.com/fhs/)): that says `/opt` is for programs that are _not packaged_ and don't follow the standards. You'd just put all the libraries there together with the program.
That is the case when you want to install storm directly from archive.

Also, using the configuration files in this repository the storm becomes packaged
and starts to follow FHS. This is achieved by giving symlinks.

See below how `$STORM_HOME` folder looks like:

```
drwxr-xr-x 2 root root  4096 Jul 24 15:00 bin
-rw-r--r-- 1 root root 34239 Jun 12 22:46 CHANGELOG.md
lrwxrwxrwx 1 root root    10 Jul 24 14:39 conf -> /etc/storm
-rw-r--r-- 1 root root   538 Mar 13 00:17 DISCLAIMER
drwxr-xr-x 2 root root  4096 Jul 24 15:00 lib
-rw-r--r-- 1 root root 22822 Jun 11 18:07 LICENSE
lrwxrwxrwx 1 root root    10 Jul 24 14:39 logback -> /etc/storm
lrwxrwxrwx 1 root root    14 Jul 24 14:39 logs -> /var/log/storm
-rw-r--r-- 1 root root   981 Jun 10 15:10 NOTICE
drwxr-xr-x 5 root root  4096 Jul 24 15:00 public
-rw-r--r-- 1 root root  7445 Jun  9 16:24 README.markdown
-rw-r--r-- 1 root root    17 Jun 16 14:22 RELEASE
-rw-r--r-- 1 root root  3581 May 29 14:20 SECURITY.md
lrwxrwxrwx 1 root root    14 Jul 24 15:37 storm-local -> /var/lib/storm
```
`var/log/storm` and `/var/lib/storm` are owned by storm user, so processes that
are also running under storm user can write state and logs.

Also `/usr/bin/storm` points to `/usr/lib/storm/bin/storm`, so, after installation storm
is accessible from command line.

This gives a precise control on configurations, log files and binaries following FHS.
Also such a schema satisfies both developers and admins paradigms.

### Logging

By default storm shipped pre-configured to log into ${storm.home}/logs/
This configuration is done in `logback.xml`.

because `${STORM_HOME}/logs/` are symlinked to `/var/log/storm` they end up where expected by admins.

#Dependencies and Requirements:


### Compile time:

Provisioning script `bootstrap.sh` installs all needed dependencies for Debian-based distribution to build a package.
Same script is used to provision Vagrant environment.

### Changelog/history

I have [previously](https://github.com/pershyn/storm-deb-packaging) used
[FPM](https://github.com/jordansissel/fpm/) to build storm 0.8 till 0.9.1.
But it was hard to maintain and also messy, while there were only potential benefits
to parametrize build for ubuntu (upstart) and theoretically rpm.

Also, before 0.9.1 building storm involved building zmq and jzmq packages.
That was a pain, details [here](https://github.com/pershyn/storm-deb-packaging/blob/37bca226b8183e86d63b40c33ffd776b7b105c23/README.md#zeromq-and-jzmq).
Now these dependencies are gone and [storm flies with netty](http://yahooeng.tumblr.com/post/64758709722/making-storm-fly-with-netty) by default.

In recent years all the major distributions moved avay from using SysVInit system, and started using [systemd](https://www.freedesktop.org/wiki/Software/systemd/). So did this project.

Upstart was supported at some point, but now ubuntu supports systemd as well. There is less motivation to support upstart.

[runit](http://smarden.org/runit/) was supported at some point, but now the autorestart is managed by systemd out of the box, and runit is not supported anymore.

### Things to do:
--------------------

- [ ] clean-up storm-local on package removal, so it doesn't collide with further installations
- [ ] storm user home??? ($STORM.HOME is owned by root.)
- [ ] check package installation behavior when home folder exists.
- [ ] https://wiki.debian.org/MaintainerScripts

## License:

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0), same as Apache Storm project.

## Links:

You may be interested to keep in mind next projects.
* [Storm framework for Mesos with Debian packaging](https://github.com/deric/storm-mesos)
* [Wirbelsturm](https://github.com/miguno/wirbelsturm) - a Vagrant and Puppet based tool to perform 1-click local and remote deployments, with a focus on big data related infrastructure.
* [storm-deploy](https://github.com/nathanmarz/storm-deploy)
* Tutorial how to install storm on .rpm based distibution - [Running multi-node storm cluster by Michael Noll](http://www.michael-noll.com/tutorials/running-multi-node-storm-cluster/)
* [Forks of storm-deb-packaging scripts that use FPM](https://github.com/pershyn/storm-deb-packaging/network)

Also, interesting materials related to this repository.
* according to [this discussion](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=621833) debian package should not remove any users on removal. Recommended behaviour is disabling a user.
* [This](http://serverfault.com/questions/96416/should-i-install-linux-applications-in-var-or-opt) is a good answer "where should software be installed".
