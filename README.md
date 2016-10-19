# Hardened BIND DNS server

The aim of this image is to create a preconfigured, highly secure BIND DNS server that can be deployed with ease. This is a chrooted BIND DNS server built on the back of the IITG AIDE (Advanced Intrusion Detection Environment) file and directory integrity checker docker image.

# Notes

The dockerfile is based on some hardening guides for bind.

# Supported Versions

BIND Version | Git branch | Tag name
-------------| ---------- |---------
9.9.4        | master     | latest
9.9.4        | 9.9.4      | 9.9.4


# Getting Started

There's two ways to get up and running, the easy way and the hard way.

## The Hard Way (Standalone)

Fire up BIND DNS server via docker run

```
docker run -d --name bind -p 53:53 -p udp/53:53 -p 953:953 -v /data/bind/custom:/var/named/chroot/custom -v /data/bind/master:/var/named/chroot/master -v /data/bind/aide:/var/lib/aide iitgdocker/bind:latest
```

## The Easy Way (Docker Compose)

The github repo contains a docker-compose.yml you can use as a base. The docker-compose.yml is compatible with docker-compose 1.5.2+.

```
bind:
  image: iitgdocker/bind:latest
  ports:
    - "53:53"
    - "53:53/udp"
    - "953:953"
  volumes:
    - /data/bind/custom:/var/named/chroot/custom
    - /data/bind/master:/var/named/chroot/master
    - /data/bind/aide:/var/lib/aide
  #environment:
    #- BIND_RNDC_SECRET=<your RNDC secret if you have one>
    #- BIND_RNDC_ALGORITHM=hmac-md5
```

By running 'docker-compose up -d' from within the same directory as your docker-compose.yml, you'll be able to bring the container up.

# Volumes

## Custom BIND named.conf

The parent named.conf (The file you're probably used to modifying) can't be modified but you can add your own named.conf file in the custom directory.
a
The run script will detect the presence of this named.conf file and automatically include it. It's from within this custom named.conf file that you should create your DNS views and override any default settings.

## Master Zone Files /var/named/chroot/master

Your DNS master zone files should be mounted here. That's probably all that needs to be said.

## AIDE Integrity Database /var/lib/aide

/var/lib/aide contains the AIDE integrity database file aide.db.tar.gz. If this file does not exist when the container starts, it will be created automatically. It is strongly recommended that this file be backed up to a secure location. This database is your baseline from which all filesystem changes are compared against so keep a copy somewhere safe.

If the start script finds a file called aide.conf in this directory, AIDE will use this instead of its default configuration file.

If changes are made to the container after its been started, you'll probably need to update the AIDE integrity database. You can do this from outside of the container by running the following command against your container:

Replace container_name with the name/id of your running container.

```
docker exec -it <container_name> /usr/sbin/aide --init
docker exec -it <container_name> mv -f /tmp/aide.db.new.gz /var/lib/aide/aide.db.gz
```

# Environment Variables

So far, these are the environment variables that are available to use.

Variable                 | Default Value (docker-compose) | Description
------------------------ | ------------------------------ |------------
BIND_RNDC_SECRET         | unset                          | Your pregenerated RNDC secret if you had one before moving to docker.
BIND_RNDC_ALGORITHM      | unset                          | The RNDC algorithm you used to generate the RNDC secret above.

# The End

If you have more ideas on how to secure this image, let us know in the comments below.
