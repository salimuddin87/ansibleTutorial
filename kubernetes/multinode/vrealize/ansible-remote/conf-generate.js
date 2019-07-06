// Copyright 2018 bad_db. All rights reserved.
// tddb CONFIDENTIAL AND TRADE SECRET
//
// Aster configuration template generator

// To use generate zipfile functionality (--zipfile), first install archiver:
// npm install archiver
//
// Usage:
//   node conf-generate.js
// Options:
//   --overwrite          : writes config templates to aster role template dir
//   --revert             : reverts to 2 workerpod, 1 partition default config
//   --config-file=<file> : specify custom config file
//   --template-dir=<dir> : specify output template directory
//   --output-dir=<dir>   : specify directory for zipfile
//   --zipfile            : generate AsterConfigs.zip containing config files
//   --debug              : Enable verbose logging

// Required libraries
const fs = require('fs');

// Aster yaml templates
const asterNamespace = "cloud-aster-ns.yaml.j2";
const platformNamespace = "cloud-platform-ns.yaml.j2";
const consulPod = "consul-pod.yaml.j2";
const consulSvc = "consul-svc.yaml.j2";
const queenExecSvc = "queenexec-svc.yaml.j2";
const queenPod = "queen-pod.yaml.j2.confman";
const registryPod = "registry-pod.yaml.j2";
const workerPod = "worker-pod.yaml.j2.confman";

var templateDir = "./roles/asterops/templates/etc/aster/manifests/";
var zipOutputDir = "./";

const defaultMemContainers = [ 'statsserver', 'txmanslave' , 'rum' ];
const configManFilename = "configManStatus.json";
const zipFilename = "AsterConfigs.zip";
const workerPodCountKey = 'WORKERPOD_COUNT';
const vworkerPerPodKey = 'PARTITIONS_PER_WORKERPOD';
// The following are the host paths only, paths in the containers remain unchanged
// local tmp space for queendb container in the queen pod
const localTmpKey = 'LOCAL_TMP';
// temp space for all the aster containers in both the queen and the worker pods
const tempSpaceKey = 'TEMPSPACE';
const queenPortKey = 'QUEEN_PORT';
const queenHttpPortKey = 'QUEEN_HTTP_PORT';
const sharedMemKey = "SHARED_MEMORY_PATH";
const qgVarPathKey = "QG_VAR_PATH";
const qgOptPathKey = "QG_OPT_PATH";
const qgTDConfigPathKey = "QG_TDCONFIG_PATH";
const rumFsCheckingIntervalKey = "RUM_FS_CHECKING_INTERVAL";
const rumFsRejectNewQueriesThresholdKey = "RUM_FS_REJECT_NEW_QUERIES_THRESHOLD";
const rumFsCancelQueriesThresholdKey = "RUM_FS_CANCEL_RUNNING_QUERIES_THRESHOLD";
// enum for memory parameters
const memKey = {
                  ARC: 'ARC_MEM',
                  ICE: 'ICE_MEM',
                  RUNNER: 'RUNNER_MEM',
                  DEFAULT: 'DEFAULT_MEM'
               }
const statsUpdateIntervalKey = "STATS_UPDATE_INTERVAL_SEC";
const slmSamplingRateKey = "SLM_SAMPLING_RATE";

// Defaults
var workerPodCount = 2;
var vworkerPerWPod = 1;
var queenPort = 30002;
var queenHttpPort = 30003;
var rumFsCheckingInterval = 30;
var rumFsRejectNewQueriesThreshold = '80%';
var rumFsCancelQueriesThreshold = '85%';
var inventoryFile = './inventory/inventory.local';
var confDir = './inventory/group_vars/';
var configFile = confDir + '/startvars.yml';
var debugFlag = false;
var generateZipFlag = false;
var overwriteFlag = false;
var revertFlag = false;
var confOutputDir='./AsterConfigs/';
var arcMem = '';
var iceMem = '';
var slmSamplingRate = 60;
var runnerMem = '';
var defaultMem = '';
var statsUpdateInterval = 5;

// Default Volume Mounts
var volumeMounts = {
   localTmp : "",
   tempSpace : "",
   sharedMemory : "/dev/shm/td_qg_ipc",
   qgVarPath : "/var/opt/tddb/tdqg",
   qgOptPath : "/opt/tddb/tdqg",
   qgTDConfigPath : "/etc/opt/tddb/tdconfig/tdqg"
};

var cmdArgs = process.argv.slice(2);
cmdArgs.forEach(function (val, index, array) {
    if(val.indexOf('--template-dir=') !== -1) {
        templateDir = val.split('=')[1];
    }
    else if(val.indexOf('--overwrite') !== -1) {
        console.log("Overwrite option specified, writing configuration templates to:");
        console.log(templateDir);
        overwriteFlag = true;
    }
    else if(val.indexOf('--revert') !== -1) {
        console.log("Reverting configuration files to original");
        revertFlag = true;
        overwriteFlag = true;
    }
    else if(val.indexOf('--zipfile') !== -1) {
        console.log("ZipFile option specified");
        generateZipFlag = true;
    }
    else if(val.indexOf('--inventory-file=') !== -1) {
        inventoryFile = val.split('=')[1];
    }
    else if(val.indexOf('--config-file=') !== -1) {
        configFile = val.split('=')[1];
    }
    else if(val.indexOf('--output-dir=') !== -1) {
        zipOutputDir = val.split('=')[1];
    }
    else if(val.indexOf('--debug') !== -1) {
        debugFlag = true;
    }
    else {
        console.log("ERROR: Unknown command " + val + ", exiting");
        process.exit(1);
    }
});


// Main
if(overwriteFlag) {
    deleteConfigStatus(templateDir);
    deletePodTempl(templateDir);
}
else {
    console.log("Configuration template output directory: " + confOutputDir);
}
if(!revertFlag) {
    processConfigInput(configFile, volumeMounts);
    writeConfigStatus(templateDir, confOutputDir);
}
generateAsterConfigs(confOutputDir);

// Copying files needed for zipfile, or if configs written to AsterConfigs/ directory
if(generateZipFlag || !overwriteFlag) {
    copyRemainingFiles(templateDir, confOutputDir);
}
if(generateZipFlag) {
    generateZip(templateDir, confOutputDir, zipFilename);
}

// Deletes all worker pod templates from aster role template directory
function deleteWorkerPodTempl(templateDir) {
    var items = fs.readdirSync(templateDir);
    for (var i=0; i<items.length; i++) {
        if(/worker[0-9]+-pod.yaml.j2/.test(items[i])) {
            if (debugFlag) {
                console.log("Deleting file " + templateDir + items[i]);
            }
            fs.unlinkSync(templateDir + items[i]);
        }
    }
}

// Deletes all worker and queen pod templates from aster role template directory
function deletePodTempl(templateDir) {
    var items = fs.readdirSync(templateDir);
    for (var i=0; i<items.length; i++) {
        if(/worker[0-9]+-pod.yaml.j2/.test(items[i]) || /queen-pod.yaml.j2$/.test(items[i])) {
            if (debugFlag) {
                console.log("Deleting file " + templateDir + items[i]);
            }
            fs.unlinkSync(templateDir + items[i]);
        }
    }
}

// Generate the workerpod and queenexec config templates
function generateAsterConfigs(temporaryDir) {
    processWorkerPodConfigs(templateDir + "/" + workerPod, workerPodCount, vworkerPerWPod, templateDir, temporaryDir, volumeMounts);
    processQueenPodConfig(templateDir + "/" + queenPod, templateDir, temporaryDir, volumeMounts);
    processQueenExec(templateDir + "/" + queenExecSvc, queenPort, queenHttpPort, templateDir, temporaryDir);
}

// Delete configuration status from template dir
function deleteConfigStatus(templateDir) {
    config = templateDir + configManFilename;
    if (debugFlag) {
        console.log("Deleting file " + config);
    }
    try {
        fs.unlinkSync(config);
    } catch (err) {
        if (debugFlag) {
            console.log(config + " does not exist");
        }
    }
}

// Delete configuration status from template dir
function deleteConfigStatus(templateDir) {
    config = templateDir + configManFilename;
    if (debugFlag) {
        console.log("Deleting file " + config);
    }
    try {
        fs.unlinkSync(config);
    } catch (err) {
        if (debugFlag) {
            console.log(config + " does not exist");
        }
    }
}

// Write status file of input configuration
function writeConfigStatus(outputDir, temporaryDir) {
    var configStatus = {};
    configStatus["vworker-workerpod-count"] = parseInt(vworkerPerWPod);
    configStatus["workerpod-count"] = parseInt(workerPodCount);
    configStatus["queen-port"] = parseInt(queenPort);
    configStatus["queen-http-port"] = parseInt(queenHttpPort);
    var jsonStatus = JSON.stringify(configStatus);

    writeToFile(outputDir, configManFilename, jsonStatus);
    if(generateZipFlag) {
        writeToFile(temporaryDir, configManFilename, jsonStatus);
    }
}

// Copyies file from src to dest
function copyFile(src, dest) {
    let readStream = fs.createReadStream(src);
    readStream.once('error', (err) => {
      console.log(err);
    });
    readStream.once('end', () => {
      if (debugFlag) console.log("Copying " + src + " to " + dest);
    });
    readStream.pipe(fs.createWriteStream(dest));
}

// Copies unmodified files from template directory to outputDirectory
function copyRemainingFiles(inputDirectory, outputDirectory) {
    remainingFiles = [asterNamespace,
                      platformNamespace,
                      consulPod,
                      consulSvc,
                      registryPod];

    for (var i = 0; i < remainingFiles.length; i++) {
        copyFile(inputDirectory + "/" + remainingFiles[i],
                 outputDirectory + "/" + remainingFiles[i]);
    }
}

// Process the configuration yaml, default startvars.yml
function processConfigInput(filename, volumeMounts) {
    if(!fs.existsSync(filename)) {
        console.log("Unable to find " + filename + ", using defaults");
        return;
    }

    configFile= fs.readFileSync(filename,'utf8');
    configFileLines = configFile.split('\n')
    for(var i = 0; i < configFileLines.length; i++) {
        if(configFileLines[i].indexOf(workerPodCountKey) !== -1) {
            workerPodCount = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(vworkerPerPodKey) !== -1) {
            vworkerPerWPod = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(queenPortKey) !== -1) {
            queenPort = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(queenHttpPortKey) !== -1) {
            queenHttpPort = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(statsUpdateIntervalKey) !== -1) {
            statsUpdateInterval = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(slmSamplingRateKey) !== -1) {
            slmSamplingRate = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(rumFsCheckingIntervalKey) !== -1) {
            rumFsCheckingInterval = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(
                                 rumFsRejectNewQueriesThresholdKey) !== -1) {
            rumFsRejectNewQueriesThreshold = 
                                 configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(
                                   rumFsCancelQueriesThresholdKey) !== -1) {
            rumFsCancelQueriesThreshold = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(memKey.ARC) !== -1) {
            arcMem = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(memKey.ICE) !== -1) {
            iceMem = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(memKey.RUNNER) !== -1) {
            runnerMem = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(memKey.DEFAULT) !== -1) {
            defaultMem = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(localTmpKey) !== -1) {
            volumeMounts["localTmp"] = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(tempSpaceKey) !== -1) {
            volumeMounts["tempSpace"] = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(sharedMemKey) !== -1) {
            volumeMounts["sharedMemory"] = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(qgVarPathKey) !== -1) {
            volumeMounts["qgVarPath"] = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(qgOptPathKey) !== -1) {
            volumeMounts["qgOptPath"] = configFileLines[i].split(':')[1].trim()
        }
        else if(configFileLines[i].indexOf(qgTDConfigPathKey) !== -1) {
            volumeMounts["qgTDConfigPath"] = configFileLines[i].split(':')[1].trim()
        }
    }

    if(debugFlag) {
        console.log(workerPodCountKey + "=" + workerPodCount + "\n" +
                    vworkerPerPodKey + "=" + vworkerPerWPod + "\n" +
                    queenPortKey + "=" + queenPort + "\n" +
                    queenHttpPortKey + "=" + queenHttpPort + "\n" +
                    statsUpdateIntervalKey + "=" + statsUpdateInterval + "\n" +
                    slmSamplingRateKey + "=" + slmSamplingRate + "\n" +
                    rumFsCheckingIntervalKey + "=" + 
                                          rumFsCheckingInterval + "\n" +
                    rumFsRejectNewQueriesThresholdKey + "=" + 
                                          rumFsRejectNewQueriesThreshold + "\n" +
                    rumFsCancelQueriesThresholdKey + "=" + 
                                          rumFsCancelQueriesThreshold + "\n" +
                    memKey.ARC + "=" + arcMem  + "\n" +
                    memKey.ICE + "=" + iceMem  + "\n" +
                    memKey.RUNNER + "=" + runnerMem  + "\n" +
                    memKey.DEFAULT + "=" + defaultMem  + "\n" +
                    sharedMemKey + "=" + volumeMounts["sharedMemory"]  + "\n" +
                    qgVarPathKey + "=" + volumeMounts["qgVarPath"]  + "\n" +
                    qgOptPathKey + "=" + volumeMounts["qgOptPath"]  + "\n" +
                    qgTDConfigPathKey + "=" + volumeMounts["qgTDConfigPath"]  + "\n" );
    }
}

// Reads default worker config and generates custom workerpod templates
function processWorkerPodConfigs(templateFilename, workerPodCount, vworkerCount, templateDir, zipDir, volumeMounts) {
    
    var workerPodConfigs = [];
    
    var workerPodTemplate = parseWorkerTemplate(templateFilename, volumeMounts);
    
    workerPartitionsSection = generatePartitions(workerPodCount, vworkerCount);
    
    for (var i = 0; i < workerPodCount; i++) {
        workerPodConfigs[i] = processWorkerHead(i, workerPodTemplate.workerPodHead);
        workerPodConfigs[i] += workerPartitionsSection[i];
        workerPodConfigs[i] += processWorkerTail(i, workerPodTemplate.workerPodTail);
        if(overwriteFlag) {
            writeToFile(templateDir,"worker" + (i+1) + "-pod.yaml.j2", workerPodConfigs[i]);
        }
        if (generateZipFlag || !overwriteFlag) {
            writeToFile(zipDir, "worker" + (i+1) + "-pod.yaml.j2", workerPodConfigs[i]);
        }
    }
}

// Reads default queen config and generates custom queenpod template
function processQueenPodConfig(templateFilename, templateDir, zipDir, volumeMounts) {
    
    var queenPodConfig = "";
    
    queenPodOut = fs.readFileSync(templateFilename,'utf8');

    //Replace the stats upate time interval value
    queenPodOut = queenPodOut.replace(
        /(STATS_UPDATE_INTERVAL_SEC\s*\n\s*value:\s*)\S*/g,
        "$1\"" + statsUpdateInterval + "\"");

    //Replace the slm polling rate
    queenPodOut = queenPodOut.replace(
        /(SLM_SAMPLING_RATE\s*\n\s*value:\s*)\S*/g,
        "$1\"" + slmSamplingRate + "\"")

    // Processes RUM container data
    queenPodOut = processRumContainerData(queenPodOut);

    // Process the mount paths with the custom paths
    queenPodOut = processVolumeMounts(volumeMounts, queenPodOut);
   
    if(overwriteFlag) {
        writeToFile(templateDir, "queen-pod.yaml.j2", queenPodOut);   
    }
    if (generateZipFlag || !overwriteFlag) {
        writeToFile(zipDir, "queen-pod.yaml.j2", queenPodOut);   
    }
    
}


// Writes string to specified file
function writeToFile(directory, filename, strToWrite) {

    if (!fs.existsSync(directory)){
        fs.mkdirSync(directory);
    }
    dirFile = directory + "/" + filename;
    fs.writeFileSync(dirFile,
            strToWrite,
            function(err) {
                if(err) {
                    return console.log(err);
                }

            }
    );
    if (debugFlag) console.log("Configuration Template written to: " + dirFile);
}

// Process first section of workerpod template
function processWorkerHead(workerPodNumber, workerPodHead) {
    return workerPodHead.replace(/name: worker\n/g, "name: worker" + (workerPodNumber + 1) + "\n");
}

// Process last section of workerpod template
function processWorkerTail(workerPodNumber, workerPodTail) {
    if (revertFlag) {
        return workerPodTail;
    }
    return workerPodTail.replace("worker1: w1pod", "worker" + (workerPodNumber + 1) + ": w" +
                                  (workerPodNumber + 1) + "pod");
}

// Generate workerpod partition number section
function generatePartitions(workerPodCount, partitionCount) {
    var partitionList = [];

    for (var i = 0; i < workerPodCount * partitionCount; i++) {
        workerSection = generateWorkerSection(i, workerPodCount);
        var currentIndex = i % workerPodCount;
        if (partitionList[currentIndex] == undefined) {
            partitionList[currentIndex] = workerSection;
        }
        else {
            partitionList[currentIndex] += workerSection;
        }
    }
    return partitionList;
}

// Generate workerpod workerdb section with custom values
function generateWorkerSection(currentCount, workerPodCount) {
    var startPort = 9001;
    var qosStartPort = 2200;
    var workerdbNum = Math.floor ((currentCount) / workerPodCount) + 1;
    var qosPort = qosStartPort + workerdbNum - 1;
    var arcPort = startPort + currentCount;

    var workerSection  = "    - name: workerdb" + workerdbNum + '\n' +
                         "      resources: " + '\n' +
                         "        requests: " + '\n' +
                         "          memory: \"{{ REQ_MEM_ARC }} \"" + '\n' +
                         "          cpu: \"{{ REQ_CPU_ARC }} \"" +  '\n' +
                     containerResourceString(arcMem) +
                     "      image: localregistryhost:localregistryport/arc:localregistrytag\n" +
                     "      env:\n" +
                     "        - name: CONTAINER_NAME\n" +
                     "          value: \"workerdb" + workerdbNum + '\"\n' +
                     "        - name: WORKER_NAME\n" +
                     "          valueFrom:\n" +
                     "            fieldRef:\n" +
                     "              fieldPath: metadata.name\n" +
                     "        - name: SYSMAN_IP\n" +
                     "          value: \"localsysmanip\"\n" +
                     "        - name: DOCKER_HOST_IP\n" +
                     "          valueFrom:\n" +
                     "            fieldRef:\n" +
                     "              fieldPath: status.podIP\n" +
                     "        - name: STATS_SERVER_IP\n" +
                     "          valueFrom:\n" +
                     "            fieldRef:\n" +
                     "              fieldPath: status.podIP\n" +
                     "        - name: QOS_SLAVE_EXEC_PORT\n" +
                     "          value: \"" + qosPort  + "\"\n" +
                     "        - name: ARC_PORT\n" +
                     "          value: \""+ arcPort +"\"\n" +
                     "        - name: STATS_UPDATE_INTERVAL_SEC\n" +
                     "          value: \""+ statsUpdateInterval +"\"\n" +
                     "      ports:\n" +
                     "        - containerPort: " + arcPort + "\n" +
                     "      volumeMounts:\n" +
                     "        - mountPath: /primary/tmp\n" +
                     "          name: worker-tempspace\n" +
                     "        - name: security-credentials\n" +
                     "          mountPath: \"/home/beehive/config/security/credentials\"\n" +
                     "        - name: arc-client-credentials\n" +
                     "          mountPath: \"/home/beehive/.postgresql\"\n" + 
                     "        - mountPath: /opt3/aster/amvdb\n" +
                     "          name: aster-amvdb\n" +
                     "          readOnly: true\n" +
                     "        - mountPath: /opt3/aster/amvDb.txt\n" +
                     "          name: asteramv\n" +
                     "          readOnly: true\n" +
                     "      securityContext:\n" +
                     "        privileged: true\n";
    return workerSection;
}


// Parse default worker template
function parseWorkerTemplate(templateFilename, volumeMounts) {
    var workerPodHead = "", workerPodTail = "";
    var writeToHead = true, writeToTail = false;

    workerPodOut = fs.readFileSync(templateFilename,'utf8');

    //Replace the stats upate time interval value
    workerPodOut = workerPodOut.replace(
        /(STATS_UPDATE_INTERVAL_SEC\s*\n\s*value:\s*)\S*/g,
        "$1\"" + statsUpdateInterval + "\"");

    // Process the mount paths with the custom paths
    workerPodOut = processVolumeMounts(volumeMounts, workerPodOut);

    // Processes RUM container data
    workerPodOut = processRumContainerData(workerPodOut);

    workerPodOut = processResources(workerPodOut);

    workerPodTmpl = workerPodOut.split('\n');
    for(var i = 0; i < workerPodTmpl.length; i++) {
        if(writeToHead) {
            if (workerPodTmpl[i].indexOf('- name: workerdb') !== -1) {
                writeToHead = false;
                continue;
            }
            workerPodHead += workerPodTmpl[i] + '\n';
        }
        if (!writeToHead && !writeToTail) {
            if((workerPodTmpl[i].startsWith('    - name:') == true) ||
               (workerPodTmpl[i].indexOf('  imagePullSecrets:') !== -1)) {
                writeToTail = true;
            }
        }
        if (writeToTail) {
            workerPodTail += workerPodTmpl[i] + '\n';
        }
    }
    return {
        workerPodHead: workerPodHead,
        workerPodTail: workerPodTail.replace(/\n$/, "")
    };
}

// Process the volumeMounts
function processVolumeMounts(volumeMounts, podTemplate) {
   if (volumeMounts["tempSpace"] != '') {
      podTemplate = podTemplate.replace(/(name: queen-tempspace\s*\n)(\s*)emptyDir: {}\s*\n/g, 
         "$1$2hostPath: \n$2  path: " + volumeMounts["tempSpace"] + "\n");
      podTemplate = podTemplate.replace(/(name: worker-tempspace\s*\n)(\s*)emptyDir: {}\s*\n/g, 
         "$1$2hostPath: \n$2  path: " + volumeMounts["tempSpace"] + "\n");
   }
   if (volumeMounts["localTmp"] != '') {
      podTemplate = podTemplate.replace(/(name: local-tmp\s*\n)(\s*)emptyDir: {}\s*\n/g, 
         "$1$2hostPath: \n$2  path: " + volumeMounts["localTmp"] + "\n");
   }
   podTemplate = podTemplate.replace(/(name: shared-memory\s*\n\s*hostPath:\s*\S*\s*\n\s*path:\s*).+\n/g, 
         "$1" + volumeMounts["sharedMemory"] + "\n");
   podTemplate = podTemplate.replace(/(name: qg-var\s*\n\s*hostPath:\s*\S*\s*\n\s*path:\s*).+\n/g, 
         "$1" + volumeMounts["qgVarPath"] + "\n");
   podTemplate = podTemplate.replace(/(name: qg-opt\s*\n\s*hostPath:\s*\S*\s*\n\s*path:\s*).+\n/g, 
         "$1" + volumeMounts["qgOptPath"] + "\n");
   podTemplate = podTemplate.replace(/(name: qg-tdconfig\s*\n\s*hostPath:\s*\S*\s*\n\s*path:\s*).+\n/g, 
         "$1" + volumeMounts["qgTDConfigPath"] + "\n");

   return podTemplate;
}

function processRumContainerData(podTemplate) {
   podTemplate = podTemplate.replace(
                  /(FS_CHECKING_INTERVAL\s*\n\s*value:\s*)\S*/, 
                  "$1\"" + rumFsCheckingInterval + "\"");
   podTemplate = podTemplate.replace(
                  /(FS_REJECT_NEW_QUERIES_THRESHOLD\s*\n\s*value:\s*)\S*/, 
                  "$1\"" + rumFsRejectNewQueriesThreshold + "\"");
   podTemplate = podTemplate.replace(
                  /(FS_CANCEL_RUNNING_QUERIES_THRESHOLD\s*\n\s*value:\s*)\S*/, 
                  "$1\"" + rumFsCancelQueriesThreshold + "\"");

   return podTemplate;
}

function processRumContainerData(podTemplate) {
   podTemplate = podTemplate.replace(
                  /(FS_CHECKING_INTERVAL\s*\n\s*value:\s*)\S*/, 
                  "$1\"" + rumFsCheckingInterval + "\"");
   podTemplate = podTemplate.replace(
                  /(FS_REJECT_NEW_QUERIES_THRESHOLD\s*\n\s*value:\s*)\S*/, 
                  "$1\"" + rumFsRejectNewQueriesThreshold + "\"");
   podTemplate = podTemplate.replace(
                  /(FS_CANCEL_RUNNING_QUERIES_THRESHOLD\s*\n\s*value:\s*)\S*/, 
                  "$1\"" + rumFsCancelQueriesThreshold + "\"");

   return podTemplate;
}


function processResources(podTemplate) {
    podTemplate = podTemplate.replace( /(- name: iceserver\n)/, 
                                       "$1" + containerResourceString(iceMem));

    podTemplate = podTemplate.replace( /(- name: runner\n)/, 
                                      "$1" + containerResourceString(runnerMem));
    defaultMemContainers.forEach(function(element) {
        var regex = new RegExp("(- name: " + element + "\n)");
        podTemplate = podTemplate.replace(regex, "$1" + containerResourceString(defaultMem));
    });
    return podTemplate;
}

// Processing the queenexec template
function processQueenExec(templateFilename, nodePort, nodeHttpPort, templateDir, zipDir) {
    queenExecTempl = fs.readFileSync(templateFilename,'utf8');
    if (!revertFlag) {
        queenExecReplaced = queenExecTempl.replace(/(\s*port:\s*2406\s*\n\s*nodePort:\s*).+/, "$1" + nodePort);
        queenExecReplaced = queenExecReplaced.replace(/(\s*port:\s*2407\s*\n\s*nodePort:\s*).+/, "$1" + nodeHttpPort);
    }
    else {
        queenExecReplaced = queenExecTempl.replace(/(\s*port: 2406\s*\n\s*nodePort:\s*).+/, "$130002");
        queenExecReplaced = queenExecReplaced.replace(/(\s*port: 2407\s*\n\s*nodePort:\s*).+/, "$130003");
    }
    if (overwriteFlag) {
        writeToFile(templateDir, queenExecSvc, queenExecReplaced);
    }
    if (generateZipFlag || !overwriteFlag) {
        writeToFile(zipDir, queenExecSvc, queenExecReplaced);
    }
}

// Returns container resource string
function containerResourceString(limit) {
    var resources = '';
    if(limit.length != 0) {
        resources = "      resources:\n" + 
                    "        limits:\n" +
                    "          memory: \"" + limit + "\"\n" +
                    "        requests:\n" + 
                    "          memory: \"" + limit + "\"\n" 
    }
    return resources;
}

// Generates output zipfile of configuration templates
function generateZip(templateDir, temporaryDir, zipFilename){
    const archiver = require('archiver');

    return new Promise(function(resolve,reject){
       var output = fs.createWriteStream(zipOutputDir + "/" + zipFilename);
       var archive = archiver('zip', {
          store: true // Sets the compression method to STORE.
       });

       // listen for all archive data to be written
       output.on('close', function() {
          if (debugFlag) console.log("Final Zip archive has " + archive.pointer() + ' total bytes\n' +
                      'Archiver has been finalized and the output file descriptor has closed.');
          resolve();
       });

       archive.on('error', function(err) {
          throw err;
       });

       // pipe archive data to the file
       archive.pipe(output);

       // append files from the output directory
       archive.directory(temporaryDir, '');

       // finalize the archive (ie we are done appending files but streams have to finish yet)
       archive.finalize();
    });
}
