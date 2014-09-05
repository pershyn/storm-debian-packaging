# Storm Debian Packaging

Debian packaging for [Apache Storm](http://storm.incubator.apache.org) distributed
realtime computation system.

The goal of this project is to provide a flexible tool to build a debian package,
that follows debian standards, uses default configs, supplied with storm release.
And also can be used as easy as storm zip unpacked elsewhere, and, at the same time,
provides a flexibility to configure it for long-term high-load production use.

I have [previously](https://github.com/pershyn/storm-deb-packaging) used
[FPM](https://github.com/jordansissel/fpm/) to build storm 0.8 till 0.9.1.
But it was hard to maintain and also messy, while there were only potential benefits
to parametrize build for ubuntu (upstart) and theoretically rpm.

Also, before 0.9.1 building storm involved building zmq and jzmq packages.
That was a pain, details [here](https://github.com/pershyn/storm-deb-packaging/blob/37bca226b8183e86d63b40c33ffd776b7b105c23/README.md#zeromq-and-jzmq).
Now these dependencies are gone and [storm flies with netty](http://yahooeng.tumblr.com/post/64758709722/making-storm-fly-with-netty) by default.

Before you proceed to build a package, you may be interested to keep in mind next projects.
* [Storm framework for Mesos with Debian packaging](https://github.com/deric/storm-mesos)
* [Wirbelsturm](https://github.com/miguno/wirbelsturm) - a Vagrant and Puppet based tool to perform 1-click local and remote deployments, with a focus on big data related infrastructure.
* [storm-deploy](https://github.com/nathanmarz/storm-deploy)
* Tutorial how to install storm on .rpm based distibution - [Running multi-node storm cluster by Michael Noll](http://www.michael-noll.com/tutorials/running-multi-node-storm-cluster/)
* [Forks of storm-deb-packaging scripts that use FPM](https://github.com/pershyn/storm-deb-packaging/network)

## Building a package:

1. Clone the repository and edit the `storm-deb-packaging/debian/changelog` to set packaging version/maintainer to your prefered values, so you get contacted if other people will use the package compiled by you.
2. Prepare the environment. You should have debian-based distribution with all tools listed in `bootstrap.sh` installed. Also, Vagrant is recommended, please find details below.
3. Run the `build.sh`. It will go to nested folder `storm-deb-packaging` and execute the `dpkg-buildpackage -rfakeroot`. The sources will be downloaded as specified in `rules` file and package would be then created in `../`. In case you want to build SNAPSHOT version - follow the instructions below.

### Creating a package of SNAPSHOT version of storm.

Follow instructions in [storm/DEVELOPER.md](https://github.com/apache/storm/blob/master/DEVELOPER.md#packaging) to create a storm distribution.

    # First, build the code.
    $ mvn clean install  # you may skip tests with `-DskipTests=true` to save time

    # Create the binary distribution.
    $ cd storm-dist/binary && mvn package

Then copy `storm-dist/binary/target/apache-storm-<version>.zip` to `storm-deb-packaging/downloads` and edit the `rules` and `changelog` files to use this zip.

## Using a package:

According to [official storm guide](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster)
you have to have next things installed:
- Java 6. But, according to [recent info](https://www.mail-archive.com/user@storm.incubator.apache.org/msg03230.html), storm-0.9.x works perfectly with java 1.6, 1.7 and 1.8. Also both openjdk and oracle jdk are supported.
- Python 2.6.6 - It may work also with other version, however this one claimed to be tested.

During the installation storm package also creates or enables existing storm user.

1. After you install a package - edit the `/etc/storm/storm.yaml` to specify nimbus and zookeeper path.
2. Start required service with corresponding command
```
#: /etc/init.d/storm-nimbus start
#: /etc/init.d/storm-ui start
#: /etc/init.d/storm-supervisor start
#: /etc/init.d/storm-drpc start
```
3. Enable those that you need to start automatically on system restart. (TODO: insert one-liner)
4. Configure storm the way you need using `/etc/storm/storm_env.ini`.
It is a good idea to use Software Configuration Management tools to manage configuration of storm clusters.
Like [saltstack](http://www.saltstack.com/),
[chef](http://www.getchef.com/chef/),
[puppet](https://puppetlabs.com/),
[ansible](http://www.ansible.com/home).

## Compatibity:

* This version is intended to be used against 0.9.2 and Debian Wheezy. Presumably it can be ran on any other debian-based distribution, because relies only on LSB. It has also upstart's conf files.
* There are previous versions (up to 0.9.1) built with FPM [here](https://github.com/pershyn/storm-deb-packaging). See tags/branches and forks.

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

### Vagrant (Optional)

The [vagrant-debian-wheezy-64](https://github.com/dotzero/vagrant-debian-wheezy-64)
scripts were used to create a vagrant box, called `wheezy64`.
This box is used as a base env to build package.

It is recommended to use vagrant to automatically provision the machine to build
the script. (relies on `wheezy64`)

```bash

# prepare and enter vm (debian)
vagrant up debian
vagrant ssh debian
# to build in ubuntu use `vagrant up ubuntu && vagrant ssh ubuntu`

cd /vagrant
# and then use commands from _Usage_ section.
```

Probably the other debian-based distribution can be used as well, if you don't have wheezy box.

### Compile time:

Provisioning script `bootstrap.sh` installs all needed dependencies for Debian-based distribution to build a package.
Same script is used to provision Vagrant environment.

Things to do:
--------------------

- [ ] Add instruction about debian insserv in ubuntu
- [ ] Ensure python 2.6.6 and java6/7 are added to package dependencies so they get installed automatically.
- [ ] add a note about separate project to 5 packages (common, nimbus, ui, supervisor, logviewer)
- [ ] clean-up storm-local on package removal, so it doesn't collide with further installations
- [ ] storm user home??? ($STORM.HOME is owned by root.)
- [ ] check package installation behavior when home folder exists.
- [ ] https://wiki.debian.org/MaintainerScripts

## Storm Package Sample Layout

After you have built a package run the next command to display package layout.
Pass-in your package name:

```
$ dpkg -c /vagrant/apache-storm_*.deb
```

### Sample layout:

```
...
```

## License:

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0), same as Apache Storm project.

## Links:

Also, interesting materials related to this repository.
* according to [this discussion](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=621833) debian package should not remove any users on removal. Recommended behaviour is disabling a user.
* [This](http://serverfault.com/questions/96416/should-i-install-linux-applications-in-var-or-opt) is a good answer "where should software be installed".
