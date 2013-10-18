# Stackbrew

Stackbrew is a web-application that performs continuous building of the docker
standard library using docker-brew.

## Install instructions

1. Install python if it isn't already available on your OS of choice
1. Install the easy_install tool (`sudo apt-get install python-setuptools`
for Debian/Ubuntu)
1. Install the python package manager, `pip` (`easy_install pip`)
1. Run the following command: `sudo pip install -r requirements.txt`
1. You should now be able to use the `brew-cli` script as such.

### Deploying stackbrew

These additional instructions are necessary for the stackbrew application to
function.

1. Install sqlite3 (`sudo apt-get install sqlite3` on Debian/Ubuntu)
1. Create the /opt/stackbrew/repos (`mkdir -p /opt/stackbrew/repos`) folder.
2. Run the `create_db.py` script (`python create_db.py`)
3. Edit `config.json` appropriately to your needs.
4. If you're using the `push` option, you will need to have a valid
   `.dockercfg` file in your HOME directory.
5. You can start the application with the command `python app.py`

## Builds

Builds are performed regularly and pushed to the public index.

## API

A small JSON API allows users to check the status of past builds.

### Latest build summary

* `GET /summary` or `GET /status`


        GET /summary

        {
            "build_date": "2013-10-04 18:08:45.685881", 
            "id": 16, 
            "result": true
        }

### Summary details

* `GET /summary/<summary_id>`


        GET /summary/16

        [
            {
                "commit_id": "7362ff5b812f93eceafbdbf5e5959f676f731f80", 
                "exception": null, 
                "source_desc": "git://github.com/dotcloud/hipache@C:7362ff5b812f93eceafbdbf5e5959f676f731f80",
                "image_id": "5d313f0ec5af",
                "tag": "0.2.4",
                "summary_id": 16,
                "id": 1,
                "repo_name": "hipache"
            }, {
                "commit_id": "7362ff5b812f93eceafbdbf5e5959f676f731f80",
                "exception": null,
                "source_desc": "git://github.com/dotcloud/hipache@C:7362ff5b812f93eceafbdbf5e5959f676f731f80",
                "image_id": "5d313f0ec5af",
                "tag": "latest",
                "summary_id": 16,
                "id": 2,
                "repo_name": "hipache"
            }, ...
        ]

### Latest successful build

* `GET /success/<repo_name>?tag=<tag>`
* `tag` parameter is optional, defaults to `latest`


        GET /success/ubuntu?tag=12.10

        {
            "commit_id": "abd58c43ceec4d4a21622a1e3d45f676fe912e745d31",
            "exception": null,
            "source_desc": "git://github.com/dotcloud/ubuntu-quantal@B:master",
            "image_id": "d462fecc33e1",
            "tag": "12.10",
            "summary_id": 17,
            "id": 19,
            "repo_name": "ubuntu"
        }

## Stackbrew CLI

    ./brew-cli -h

Display usage and help.

    ./brew-cli

Default build from the default repo/branch. Images will be created under the
`library/` namespace. Does not perform a remote push.

    ./brew-cli -n mycorp.com -b stable --push git://github.com/mycorp/docker

Will fetch the library definition files in the `stable` branch of the
`git://github.com/mycorp/docker` repository and create images under the
`mycorp.com` namespace (e.g. `mycorp.com/ubuntu`). Created images will then
be pushed to the official docker repository (pending: support for private
repositories)