# Stackbrew

Stackbrew is a web-application that performs continuous building of the docker
standard library using docker-brew.

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
