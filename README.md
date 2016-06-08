# salt-manage-hosts

Command line wrapper to bootstrap salt managed hosts (minion).

With [salt-bootstrap](https://github.com/saltstack/salt-bootstrap)


**Require:** ssh server runing on the minion, and a root ssh key on it.

Tested on OVH VPS, with debian 8 jessie.

*Lecteurs francophones: Demandez une traduction de la doc, je la fournirai. ;)/)*

## Installation

~~~
git clone git@github.com:opensource-expert/salt-manage-hosts.git
~~~

You will also need to have [salt-bootstrap](https://github.com/saltstack/salt-bootstrap) cloned

(on the saltmaster)
~~~
cd /root
git clone https://github.com/saltstack/salt-bootstrap.git
~~~

## Configure

You can modify top variables in `bootstrap-minion.sh` or create a `bootstrap.conf` which will be sourced and will 
override the default values. Upload of the `bootstrap.conf` on the minion is handled by the script, so
your config will be there too. ;)

`bootstrap.conf`:

~~~bash
#!/bin/bash
saltmaster=saltmaster.my-favorite.dns.name
~~~

## bootstrap a minion

Ensure that your root ssh key is working on the server (after reninstall it wont work)

~~~
ssh -o StrictHostKeyChecking=no -y root@mynew.server.name hostname
~~~

`hostname` can be different than dns name, which will be fixed by the script, which happens on fresh
new VM installed by some provider.

Note: update your `~/.ssh/know_hosts` if needed

Run the script from the saltmaster:

~~~
./bootstrap-minion.sh mynew.server.name
~~~

Wait…

When finished, you should be able to accept minion's key

~~~
salt-key -L
~~~


Accept it:

~~~
salt-key -A mynew.server.name
~~~

Now, everything else can be done via salt, Enjoy!

## Extra

Add short dns names to your minion in `/etc/hosts`…
Not done by the script. Nothing is changed on the saltmaster, except if you bootstrap itself with the script.

## Details

See source code for more details.

The code is wrapped inside small bash functions which are easy to debug.

The `main()` function wraps that saltmaster/minion exec mode and ssh tricks.
As a python module, when sourced the script does nothing.

