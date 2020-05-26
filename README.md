OpenVAS image for Docker (now simplified)
=========================================

[![Docker Pulls](https://img.shields.io/docker/pulls/myoung34/openvas.svg)](https://hub.docker.com/r/myoung34/openvas)

A Docker container for OpenVAS on Ubuntu.  By default, it will update the nvt's and cert's on startup in the background, so the first run can be slow.


| Openvas Version | Tag     | Web UI Port |
|-----------------|---------|-------------|
| 9               | latest  | 4000        |



Usage
-----

Simply run:

```
# Note: 9390 is the OpenVAS manager port
$ docker run -d -p 4000:4000 -p 9390:9390 ---name openvas --rm myoung34/openvas

# Specify DNS Hostname
# By default, the system only allows connections for the hostname "openvas".  
# To allow access using a custom DNS name, you must use this command:

$ docker run -d -p 4000:4000 -p 9390:9390 --e ALLOW_HEADER_HOST=foo.domain.tld --name openvas --rm myoung34/openvas

$ docker run -d -p 4000:4000 -p 9390:9390 --v $(pwd)/data:/var/lib/openvas/mgr/ --name openvas myoung34/openvas

$ docker run -d -p 4000:4000 -p 9390:9390 --name openvas myoung34/openvas

# to set the admin password
$ docker run -d -p 4000:4000 -e OV_PASSWORD=securepassword41 --name openvas myoung34/openvas
```

This will grab the container from the docker registry and start it up.  Openvas startup can take some time (4-5 minutes while NVT's are scanned and databases rebuilt), so be patient.  Once you see a `It seems like your OpenVAS-9 installation is OK.` process in the logs, the web ui is good to go.  Goto `http://<machinename>`

```
Username: admin
Password: admin
```

#### Update NVTs
Occasionally you'll need to update NVTs. We update the container about once a week but you can update your container by execing into the container and running a few commands:
```
docker exec -it openvas bash
## inside container
greenbone-nvt-sync
openvasmd --rebuild --progress
greenbone-certdata-sync
greenbone-scapdata-sync
openvasmd --update --verbose --progress

/etc/init.d/openvas-manager restart
/etc/init.d/openvas-scanner restart
```

Contributing
------------

I'm always happy to accept [pull requests](https://github.com/myoung34/openvas-docker/pulls) or [issues](https://github.com/myoung34/openvas-docker/issues).

Thanks
------
Thanks to hackertarget for the great tutorial: http://hackertarget.com/install-openvas-7-ubuntu/
Thanks to Serge Katzmann for contributing with some great work on OpenVAS 8: https://github.com/sergekatzmann/openvas8-complete
Thanks to mikesplain for the initial pass, it was just overly complex and unmaintained
