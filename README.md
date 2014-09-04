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
3. Run the `build.sh`. It will go to nested folder `storm-deb-packaging` and execute the `dpkg-buildpackage -rfakeroot`. The sources will be downloaded as specified in `rules` file and package would be then created in `../`

## Using a package:

According to [official storm guide](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster)
you have to have next things installed:
- Java 6
- Python 2.6.6

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
vagrant up
vagrant ssh
cd /vagrant
# and then use commands from _Usage_ section.
```

Probably the other debian-based distribution can be used as well, if you don't have wheezy box.

### Compile time:

Provisioning script `bootstrap.sh` installs all needed dependencies for Debian-based distribution to build a package.
Same script is used to provision Vagrant environment.

Things to do:
--------------------

- [ ] Debian lsb in ubuntu
- [ ] Debian insserv in ubuntu
- [ ] Why people write upstart scripts.
- [ ] Ensure python 2.6.6 and java6 are added to package dependencies so they get installed automatically.
- [ ] add a note about separate project to 4 packages (common, nimbus, ui, supervisor)
- [ ] clean-up storm-local on package removal, so it doesn't collide with further installations
- [ ] storm user home??? ($STORM.HOME is owned by root.)
- [ ] check package installation behaviour when home folder exists.
- [ ] https://wiki.debian.org/MaintainerScripts
- [ ] Symlinks /etc/init.d/storm-* services to /lib/init/upstart-job. for ubuntu support??? check ubuntu upstart...

## Storm Package Sample Layout

```
$ dpkg -c /vagrant/apache-storm_0.9.2-incubating_all.deb

drwxr-xr-x root/root         0 2014-10-23 14:16 ./
drwxr-xr-x root/root         0 2014-10-23 14:16 ./var/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./var/lib/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./var/lib/storm/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./var/lib/storm/storm-local/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./var/log/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./var/log/storm/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/share/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/share/doc/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/share/doc/apache-storm/
-rw-r--r-- root/root       215 2014-07-23 14:49 ./usr/share/doc/apache-storm/copyright
-rw-r--r-- root/root       184 2014-10-23 13:50 ./usr/share/doc/apache-storm/changelog.Debian.gz
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/lib/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/lib/storm/
-rw-r--r-- root/root        17 2014-06-16 12:22 ./usr/lib/storm/RELEASE
-rw-r--r-- root/root       981 2014-06-10 13:10 ./usr/lib/storm/NOTICE
-rw-r--r-- root/root       538 2014-03-12 23:17 ./usr/lib/storm/DISCLAIMER
drwxr-xr-x root/root         0 2014-06-16 12:22 ./usr/lib/storm/public/
-rw-r--r-- root/root      4141 2014-06-11 16:07 ./usr/lib/storm/public/index.html
drwxr-xr-x root/root         0 2014-05-29 12:20 ./usr/lib/storm/public/css/
-rw-r--r-- root/root     56497 2014-03-12 23:17 ./usr/lib/storm/public/css/bootstrap-1.4.0.css
-rw-r--r-- root/root      1088 2014-05-29 12:20 ./usr/lib/storm/public/css/style.css
drwxr-xr-x root/root         0 2014-06-11 17:03 ./usr/lib/storm/public/templates/
-rw-r--r-- root/root      9880 2014-06-11 17:03 ./usr/lib/storm/public/templates/topology-page-template.html
-rw-r--r-- root/root     13535 2014-06-11 16:07 ./usr/lib/storm/public/templates/component-page-template.html
-rw-r--r-- root/root       884 2014-06-11 16:07 ./usr/lib/storm/public/templates/json-error-template.html
-rw-r--r-- root/root      4685 2014-06-11 16:07 ./usr/lib/storm/public/templates/index-page-template.html
drwxr-xr-x root/root         0 2014-06-11 16:07 ./usr/lib/storm/public/js/
-rw-r--r-- root/root     15826 2014-06-09 14:45 ./usr/lib/storm/public/js/arbor-tween.js
-rw-r--r-- root/root     16959 2014-06-11 15:04 ./usr/lib/storm/public/js/jquery.mustache.js
-rw-r--r-- root/root      5017 2014-06-09 14:25 ./usr/lib/storm/public/js/script.js
-rw-r--r-- root/root      5496 2013-12-05 12:33 ./usr/lib/storm/public/js/jquery.cookies.2.2.0.min.js
-rw-r--r-- root/root     14975 2014-06-11 16:07 ./usr/lib/storm/public/js/visualization.js
-rw-r--r-- root/root     15976 2014-06-09 14:45 ./usr/lib/storm/public/js/arbor-graphics.js
-rw-r--r-- root/root     27481 2014-06-09 14:45 ./usr/lib/storm/public/js/arbor.js
-rw-r--r-- root/root     91555 2013-12-05 12:33 ./usr/lib/storm/public/js/jquery-1.6.2.min.js
-rw-r--r-- root/root     16532 2013-12-05 12:33 ./usr/lib/storm/public/js/jquery.tablesorter.min.js
-rw-r--r-- root/root      8830 2014-06-09 14:25 ./usr/lib/storm/public/js/purl.js
-rw-r--r-- root/root      7981 2014-03-12 23:17 ./usr/lib/storm/public/js/bootstrap-twipsy.js
-rw-r--r-- root/root      5093 2014-06-11 16:07 ./usr/lib/storm/public/topology.html
-rw-r--r-- root/root      5475 2014-06-11 16:07 ./usr/lib/storm/public/component.html
-rw-r--r-- root/root      3581 2014-05-29 12:20 ./usr/lib/storm/SECURITY.md
drwxr-xr-x root/root         0 2014-06-16 12:22 ./usr/lib/storm/lib/
-rw-r--r-- root/root     67254 2014-02-26 12:39 ./usr/lib/storm/lib/curator-client-2.4.0.jar
-rw-r--r-- root/root     65612 2013-12-27 14:24 ./usr/lib/storm/lib/reflectasm-1.07-shaded.jar
-rw-r--r-- root/root    208781 2013-12-27 14:23 ./usr/lib/storm/lib/jline-2.11.jar
-rw-r--r-- root/root      3122 2013-12-27 14:24 ./usr/lib/storm/lib/clout-1.0.1.jar
-rw-r--r-- root/root      3210 2013-12-27 14:24 ./usr/lib/storm/lib/ring-servlet-0.3.11.jar
-rw-r--r-- root/root    785556 2014-02-26 12:14 ./usr/lib/storm/lib/netty-3.2.2.Final.jar
-rw-r--r-- root/root    232771 2014-01-05 20:55 ./usr/lib/storm/lib/commons-codec-1.6.jar
-rw-r--r-- root/root    185140 2014-01-30 21:17 ./usr/lib/storm/lib/commons-io-2.4.jar
-rw-r--r-- root/root     21932 2013-12-27 14:24 ./usr/lib/storm/lib/ring-core-1.1.5.jar
-rw-r--r-- root/root    282269 2014-03-26 14:41 ./usr/lib/storm/lib/httpcore-4.3.2.jar
-rw-r--r-- root/root   5308970 2014-06-13 16:57 ./usr/lib/storm/lib/storm-core-0.9.2-incubating.jar
-rw-r--r-- root/root     46022 2013-12-27 14:24 ./usr/lib/storm/lib/asm-4.0.jar
-rw-r--r-- root/root      6367 2013-12-27 14:24 ./usr/lib/storm/lib/ring-devel-0.3.11.jar
-rw-r--r-- root/root    333259 2013-12-27 14:24 ./usr/lib/storm/lib/jgrapht-core-0.9.0.jar
-rw-r--r-- root/root    179720 2014-02-26 12:39 ./usr/lib/storm/lib/curator-framework-2.4.0.jar
-rw-r--r-- root/root     16046 2013-12-27 14:24 ./usr/lib/storm/lib/json-simple-1.1.jar
-rw-r--r-- root/root   1202373 2013-12-27 14:24 ./usr/lib/storm/lib/netty-3.6.3.Final.jar
-rw-r--r-- root/root    177131 2013-12-27 14:24 ./usr/lib/storm/lib/jetty-util-6.1.26.jar
-rw-r--r-- root/root      6372 2013-12-27 14:24 ./usr/lib/storm/lib/compojure-1.1.3.jar
-rw-r--r-- root/root      4965 2013-12-27 14:24 ./usr/lib/storm/lib/minlog-1.2.jar
-rw-r--r-- root/root    270553 2013-12-27 14:24 ./usr/lib/storm/lib/snakeyaml-1.11.jar
-rw-r--r-- root/root    363460 2014-03-26 12:22 ./usr/lib/storm/lib/kryo-2.21.jar
-rw-r--r-- root/root    251784 2013-12-27 14:24 ./usr/lib/storm/lib/logback-classic-1.0.6.jar
-rw-r--r-- root/root    349706 2013-12-27 14:24 ./usr/lib/storm/lib/logback-core-1.0.6.jar
-rw-r--r-- root/root     51426 2013-12-27 14:24 ./usr/lib/storm/lib/disruptor-2.10.1.jar
-rw-r--r-- root/root     57779 2013-12-27 14:23 ./usr/lib/storm/lib/commons-fileupload-1.2.1.jar
-rw-r--r-- root/root     25962 2013-12-27 14:24 ./usr/lib/storm/lib/slf4j-api-1.6.5.jar
-rw-r--r-- root/root    569231 2013-12-27 14:24 ./usr/lib/storm/lib/joda-time-2.0.jar
-rw-r--r-- root/root    589512 2014-03-26 14:41 ./usr/lib/storm/lib/httpclient-4.3.3.jar
-rw-r--r-- root/root     20647 2013-12-27 14:24 ./usr/lib/storm/lib/log4j-over-slf4j-1.6.6.jar
-rw-r--r-- root/root     62050 2014-01-30 21:06 ./usr/lib/storm/lib/commons-logging-1.1.3.jar
-rw-r--r-- root/root      2441 2013-12-27 14:24 ./usr/lib/storm/lib/ring-jetty-adapter-0.3.11.jar
-rw-r--r-- root/root      4646 2013-12-27 14:24 ./usr/lib/storm/lib/math.numeric-tower-0.0.1.jar
-rw-r--r-- root/root      3429 2014-05-07 12:07 ./usr/lib/storm/lib/tools.cli-0.2.4.jar
-rw-r--r-- root/root     52543 2013-12-27 14:24 ./usr/lib/storm/lib/commons-exec-1.1.jar
-rw-r--r-- root/root    539912 2013-12-27 14:24 ./usr/lib/storm/lib/jetty-6.1.26.jar
-rw-r--r-- root/root     46717 2014-03-26 12:22 ./usr/lib/storm/lib/chill-java-0.3.5.jar
-rw-r--r-- root/root      7088 2013-12-27 14:24 ./usr/lib/storm/lib/tools.logging-0.2.3.jar
-rw-r--r-- root/root    134133 2013-12-27 14:24 ./usr/lib/storm/lib/servlet-api-2.5-20081211.jar
-rw-r--r-- root/root   3585371 2013-12-29 23:47 ./usr/lib/storm/lib/clojure-1.5.1.jar
-rw-r--r-- root/root      6204 2013-12-27 14:23 ./usr/lib/storm/lib/clj-stacktrace-0.2.4.jar
-rw-r--r-- root/root    105112 2013-12-27 14:23 ./usr/lib/storm/lib/servlet-api-2.5.jar
-rw-r--r-- root/root      3129 2013-12-27 14:24 ./usr/lib/storm/lib/core.incubator-0.1.0.jar
-rw-r--r-- root/root    279193 2013-12-27 14:21 ./usr/lib/storm/lib/commons-lang-2.5.jar
-rw-r--r-- root/root     26245 2014-03-26 12:22 ./usr/lib/storm/lib/carbonite-1.4.0.jar
-rw-r--r-- root/root    779974 2014-01-22 01:37 ./usr/lib/storm/lib/zookeeper-3.4.5.jar
-rw-r--r-- root/root      9386 2013-12-27 14:24 ./usr/lib/storm/lib/clj-time-0.4.1.jar
-rw-r--r-- root/root     36046 2013-12-27 14:24 ./usr/lib/storm/lib/objenesis-1.2.jar
-rw-r--r-- root/root      5170 2013-12-27 14:24 ./usr/lib/storm/lib/tools.macro-0.1.0.jar
-rw-r--r-- root/root   1891102 2013-12-27 14:24 ./usr/lib/storm/lib/guava-13.0.jar
-rw-r--r-- root/root      7898 2013-12-27 14:24 ./usr/lib/storm/lib/hiccup-0.3.6.jar
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/lib/storm/bin/
-rwxr-xr-x root/root     16901 2014-05-29 12:20 ./usr/lib/storm/bin/storm
-rw-r--r-- root/root      7445 2014-06-09 14:24 ./usr/lib/storm/README.markdown
-rw-r--r-- root/root     34239 2014-06-12 20:46 ./usr/lib/storm/CHANGELOG.md
-rw-r--r-- root/root     22822 2014-06-11 16:07 ./usr/lib/storm/LICENSE
drwxr-xr-x root/root         0 2014-10-23 14:16 ./usr/bin/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./etc/
drwxr-xr-x root/root         0 2014-10-23 14:16 ./etc/init.d/
-rwxr-xr-x root/root      1726 2014-10-23 13:55 ./etc/init.d/storm-ui
-rwxr-xr-x root/root      1738 2014-10-23 13:54 ./etc/init.d/storm-drpc
-rwxr-xr-x root/root      1817 2014-10-23 13:55 ./etc/init.d/storm-supervisor
-rwxr-xr-x root/root      1769 2014-10-23 13:55 ./etc/init.d/storm-nimbus
drwxr-xr-x root/root         0 2014-10-23 14:16 ./etc/init/
-rw-r--r-- root/root       308 2014-10-23 13:51 ./etc/init/storm-drpc.conf
-rw-r--r-- root/root       316 2014-10-23 13:51 ./etc/init/storm-nimbus.conf
-rw-r--r-- root/root       332 2014-10-23 13:51 ./etc/init/storm-supervisor.conf
-rw-r--r-- root/root       300 2014-10-23 13:51 ./etc/init/storm-ui.conf
drwxr-xr-x root/root         0 2014-10-23 14:16 ./etc/storm/
-rw-r--r-- root/root      3083 2014-05-28 12:24 ./etc/storm/cluster.xml
-rw-r--r-- root/root      1126 2014-05-28 12:24 ./etc/storm/storm_env.ini
-rw-r--r-- root/root      1613 2014-05-28 12:24 ./etc/storm/storm.yaml
lrwxrwxrwx root/root         0 2014-10-23 14:16 ./usr/lib/storm/conf -> /etc/storm
lrwxrwxrwx root/root         0 2014-10-23 14:16 ./usr/lib/storm/logback -> /etc/storm
lrwxrwxrwx root/root         0 2014-10-23 14:16 ./usr/lib/storm/storm-local -> /var/lib/storm/storm-local
lrwxrwxrwx root/root         0 2014-10-23 14:16 ./usr/lib/storm/logs -> /var/log/storm
lrwxrwxrwx root/root         0 2014-10-23 14:16 ./usr/bin/storm -> ../lib/storm/bin/storm
```

## License:

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0), same as Apache Storm project.

## Links:

Also, interesting materials related to this repository.
* according to [this discussion](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=621833) debian package should not remove any users on removal. Recommended behaviour is disabling a user.
* [This](http://serverfault.com/questions/96416/should-i-install-linux-applications-in-var-or-opt) is a good answer "where should software be installed".
