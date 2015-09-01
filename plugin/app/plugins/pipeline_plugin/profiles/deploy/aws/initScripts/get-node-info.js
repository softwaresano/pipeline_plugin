"use strict";

var async = require("async"),
    request = require("request"),
    fs = require("fs"),
    targetFile = "/etc/puppet/files/resultados.json",
    hieraFile = "/var/lib/puppet/hieradata/common.yaml";

function extractNodeList(data, callback) {
    var objectList = JSON.parse(data),
        results = [];

    for (var i in objectList) {
        results.push(objectList[i].name);
    }

    callback(null, results);
}

function requestNodeList(callback) {
    var options = {
        url: "http://localhost:8080/v2/nodes",
        method: "GET",
        headers: {
            Accept: "application/json"
        }
    }

    request(options, function (error, response, body) {
        if (error) {
            console.log("Couldn't read Node list: " + error);
            callback(error);
        } else {
            callback(null, body);
        }
    });
}

function requestNodeInfo(node, callback) {
    var options = {
        url: "http://localhost:8080/v2/nodes/" + node + "/facts",
        method: "GET",
        headers: {
            Accept: "application/json"
        }
    }

    request(options, function (error, response, body) {
        if (error) {
            console.log("Couldn't read Node fact list: " + error);
            callback(error);
        } else {
            callback(null, body);
        }
    });
}

function processNodesInfo(globalCallback) {
    return function (error, resultArray) {
        if (error) {
            console.log("Couldn't retrieve a particular node info: " + error);
            globalCallback(error);
        } else {
            var result = {},
                layer;

            for (var i in resultArray) {
                var node = JSON.parse(resultArray[i]),
                    resultNode = {},
                    cleanNode = {};

                for (var attr in node) {
                    resultNode[node[attr].name] = node[attr].value;
                }

                cleanNode['fqdn'] = resultNode['fqdn'];
                layer = cleanNode['fqdn'].substring(0, cleanNode['fqdn'].indexOf('-'));

                cleanNode['ip'] = resultNode['ipaddress_eth0'];
                cleanNode['public_name'] = resultNode['ec2_public_hostname'];
                cleanNode['private_name'] = resultNode['ec2_hostname'];

                if (!result[layer]) {
                    result[layer] = [];
                }

                result[layer].push(cleanNode);
            }

            globalCallback(null, result);
        }
    }
}

function extractNodesInfo(nodeList, callback) {
    async.map(nodeList, requestNodeInfo, processNodesInfo(callback));
}

function toYaml(data) {
    var result = "---\n";

    for (var layer in data) {
        result += layer + ":\n"

        for (var i in data[layer]) {
            result += "- hostname: " + data[layer][i].private_name + "\n";
            result += "  ip: " + data[layer][i].ip + "\n";
            result += "  public_name: " + data[layer][i].public_name + "\n";
            result += "  fqdn: " + data[layer][i].fqdn + "\n";
        }
    }

    return result;
}

function processResults(error, results) {
    async.series([
        async.apply(fs.writeFile, targetFile, JSON.stringify(results)),
        async.apply(fs.writeFile, hieraFile, toYaml(results))
    ], function (error) {
        if (error) {
            console.error("Couldn't write the results file to disk: " + error);
        } else {
            console.log("Node info written successfully");
        }
    });
}

function updateInfo() {
    async.waterfall([
        requestNodeList,
        extractNodeList,
        extractNodesInfo
    ], processResults);
}

updateInfo();
