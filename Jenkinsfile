#!/usr/bin/env groovy

def nodes = [:]

// https://stackoverflow.com/a/44159250/1559300
properties([
    buildDiscarder(logRotator(daysToKeepStr: '3', numToKeepStr: '3')),
    pipelineTriggers([cron('H H * * *')]),
])

// https://stackoverflow.com/a/61692506/1559300
nodesByLabel('base-images').each {
    nodes[it] = { ->
        node(it) {
            stage("docker-prune@${it}") {
                sh('docker system prune -af --filter "until=72h"')
                sh('docker system prune -af --volumes')
            }
        }
    }
}

timeout(time: 3, unit: 'HOURS') {
    parallel nodes
}

