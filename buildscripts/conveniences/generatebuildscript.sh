#!/usr/bin/python

##Licensed to the Apache Software Foundation (ASF) under one
##or more contributor license agreements.  See the NOTICE file
##distributed with this work for additional information
##regarding copyright ownership.  The ASF licenses this file
##to you under the Apache License, Version 2.0 (the
##"License"); you may not use this file except in compliance
##with the License.  You may obtain a copy of the License at
##
##  http://www.apache.org/licenses/LICENSE-2.0
##
##Unless required by applicable law or agreed to in writing,
##software distributed under the License is distributed on an
##"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
##KIND, either express or implied.  See the License for the
##specific language governing permissions and limitations
##under the License.

import locale
from datetime import datetime

## tools needed
maven339='Maven 3.3.9'
jdk8='JDK 1.8 (latest)'
ant10='Ant (latest)'

## information for each release (tools + date of release to flag the doc)
## pick tools that are available on ubuntu node on build.apache.org
releaseinfo=[
['release90', '97904961e496383d6150aef9b78fa8dff8f3e1ce', True,jdk8,maven339,ant10,'1.4-SNAPSHOT', 'RELEASE90','org.apache.netbeans:netbeans-parent:1', 'http://bits.netbeans.org/9.0/javadoc', datetime(2018,07,29,12,00), 'incubator-netbeans-release-334-on-20180708'],
['release100','910bd74bf46d079e49925f702432c74d54ec705c', True,jdk8,maven339,ant10,'1.4-SNAPSHOT','RELEASE100','org.apache.netbeans:netbeans-parent:1','http://bits.netbeans.org/10.0/javadoc', datetime(2018,12,27,12,00), 'incubator-netbeans-release-380-on-20181217'],
['release110','275dea5557510c107cf9d193fe61555aacd544b1', True,jdk8,maven339,ant10,'1.4-SNAPSHOT','RELEASE110','org.apache.netbeans:netbeans-parent:1','http://bits.netbeans.org/11.0/javadoc', datetime(2019,02,13,12,00), 'incubator-netbeans-release-404-on-20190319'],
## not yet (under review)
#['release120','        ', True,jdk8,maven339,ant10,'1.4-SNAPSHOT','RELEASE120','org.apache.netbeans:netbeans-parent:1','http://bits.netbeans.org/12.0/javadoc', datetime(2019,02,13,12,00)],
##master branch
['master','', True,jdk8,maven339,ant10,'1.4-SNAPSHOT','dev-SNAPSHOT','org.apache.netbeans:netbeans-parent:1']] ## no need custom info

def write_pipelinebasic(afile,scm,jdktool,maventool,anttool,buildnumber):
  afile.write("// generated by generatebuilscript.sh\n")
  afile.write("pipeline {\n")
  afile.write("   agent  { label 'ubuntu' }\n")
  afile.write("   options {\n")
  afile.write("      buildDiscarder(logRotator(numToKeepStr: '1'))\n")
  afile.write("      disableConcurrentBuilds() \n")
  afile.write("   }\n")
  afile.write("   triggers {\n")
  afile.write("      pollSCM('H/30 * * * * ')\n")
  afile.write("   }\n")
  afile.write("   environment {\n")
  if buildnumber=='':
      afile.write('     buildnumber = "${BUILD_TIMESTAMP}" \n')
  else:
      afile.write("     buildnumber = '" + buildnumber+ "' \n")
  afile.write("   }\n")
  afile.write("   tools {\n")
  afile.write("      maven '"+maventool+"'\n")
  afile.write("      jdk '"+jdktool+"'\n")
  afile.write("   }\n")
  afile.write("   stages {\n")
  afile.write("      stage('Informations') {\n")
  afile.write("          steps {\n")
  afile.write("              slackSend (channel:'#netbeans-builds', message:"+'"'+"STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' ($env.BUILD_URL), Branch we are building is : "+scm+'"'+",color:'#f0f0f0')"+"\n")
  afile.write("          }\n")
  afile.write("      }\n")

def write_pipelinecheckout(afile,scm,poll):
  afile.write("      stage('SCM operation') {\n")
  afile.write("          steps {\n")
  afile.write("              dir ('netbeanssources') {\n")
  afile.write("              echo 'Get NetBeans sources'\n")
  if poll=="":
     afile.write("              checkout([$class: 'GitSCM', branches: [[name: '"+scm+"']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', noTags: false, reference: '', shallow: true]], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/apache/netbeans/']]])\n")
  else:
     afile.write("              checkout changelog:false, poll:false, scm:[$class: 'GitSCM', branches: [[name: '"+scm+"']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', noTags: false, reference: '', shallow: true]], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/apache/netbeans/']]]\n")
  afile.write("              }\n")
  afile.write("          }\n")
  afile.write("      }\n")

def write_pipelineclose(afile):
## close stage
  afile.write("   }\n")
  afile.write("   post {\n")
  afile.write("     cleanup  {\n")
  afile.write("         cleanWs()\n")
  afile.write("     }\n")
  afile.write("     success {\n")
  afile.write("       slackSend (channel:'#netbeans-builds', message:"+'"'+"SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}) "+'"'+",color:'#00FF00')"+"\n")
  afile.write("     }\n")
  afile.write("     failure {\n")
  afile.write("       slackSend (channel:'#netbeans-builds', message:"+'"'+"FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'  (${env.BUILD_URL})"+'"'+",color:'#FF0000')"+"\n")
  afile.write("     }\n")
  afile.write("   }\n")
## close pipeline
  afile.write("}\n")
  afile.close

##for each release generate a file

for arelease in releaseinfo:
  branch='refs/heads/'+arelease[0]
  if arelease[1]=='':
    tag=branch
  else:
    tag=''+arelease[1]
  jdktool=arelease[3]
  maventool=arelease[4]
  anttool=arelease[5]
  mavenbuildfile =  open ('generated/Jenkinsfile-maven-' +arelease[0]+'.groovy',"w")
  if branch=='refs/heads/master':
      buildnumber = ""
  else:
      buildnumber = arelease[11]
  write_pipelinebasic(mavenbuildfile ,tag,   jdktool,maventool,anttool,buildnumber)

## needed until we had mavenutil ready
##prepare nb-repository from master to populate
  if arelease[2] == True:
     mavenbuildfile.write("      stage('mavenutils preparation') {\n")
     mavenbuildfile.write("          // this stage is temporary\n")
     mavenbuildfile.write("          steps {\n")
     mavenbuildfile.write("              echo 'Get Mavenutils sources'\n")
     mavenbuildfile.write("              sh 'rm -rf mavenutils'\n")
     mavenbuildfile.write("              dir('mavenutils') {\n")
     mavenbuildfile.write("                 checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', noTags: true, reference: '', shallow: true]], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/apache/netbeans-mavenutils/']]])\n")
     mavenbuildfile.write("              }\n")
     mavenbuildfile.write("              script {\n")
     mavenbuildfile.write("                 def mvnfoldersforsite  = ['parent','nbm-shared','nb-repository-plugin']\n");
     mavenbuildfile.write("                 for (String mvnproject in mvnfoldersforsite) {\n")
     mavenbuildfile.write("                     dir('mavenutils/'+mvnproject) {\n")
     mavenbuildfile.write("                        sh "+'"'+'mvn clean install -Dmaven.repo.local=${env.WORKSPACE}/.repository'+'"'+"\n")
     mavenbuildfile.write("                     }\n")
     mavenbuildfile.write("                 }\n")
     mavenbuildfile.write("              }\n")
     mavenbuildfile.write("          }\n")
     mavenbuildfile.write("      }\n")

  if branch=='refs/heads/master':
     write_pipelinecheckout(mavenbuildfile,tag,"")
  else:
     write_pipelinecheckout(mavenbuildfile,tag,"poll:false")
## build netbeans all needed for javadoc and nb-repository plugin

## build artefacts for maven
  mavenbuildfile.write("      stage('NetBeans Builds') {\n")
  mavenbuildfile.write("          steps {\n")
  mavenbuildfile.write("              dir ('netbeanssources'){\n")
  mavenbuildfile.write("                  withAnt(installation: '"+anttool+"') {\n")
  mavenbuildfile.write('                      sh "ant -Dbuildnumber=${env.buildnumber}"\n')
  mavenbuildfile.write('                      sh "ant build-javadoc -Dbuildnumber=${env.buildnumber}"\n')
  mavenbuildfile.write('                      sh "ant build-source-zips -Dbuildnumber=${env.buildnumber}"\n')
  mavenbuildfile.write('                      sh "ant build-nbms -Dbuildnumber=${env.buildnumber}"\n')
  mavenbuildfile.write("                  }\n")
  mavenbuildfile.write("              }\n")

#prepare maven artifacts
  mavenbuildfile.write("              script {\n")
  nbbuildpath = "${env.WORKSPACE}/netbeanssources/nbbuild"
  mavenbuildfile.write("                        sh 'rm -rf testrepo/.m2'\n")
  mavenbuildfile.write("                        sh "+'"'+'mvn org.apache.netbeans.utilities:nb-repository-plugin:'+arelease[6]+':download -DnexusIndexDirectory=${env.WORKSPACE}/repoindex -Dmaven.repo.local=${env.WORKSPACE}/.repository'+ ' -DrepositoryUrl=https://repo.maven.apache.org/maven2"'+"\n")
  mavenbuildfile.write("                        sh 'mkdir -p testrepo/.m2'\n")
  mavenbuildfile.write("                        sh "+'"'+'mvn org.apache.netbeans.utilities:nb-repository-plugin:'+arelease[6]+':populate -DnexusIndexDirectory=${env.WORKSPACE}/repoindex -DnetbeansNbmDirectory='+nbbuildpath+'/nbms -DnetbeansInstallDirectory='+nbbuildpath+'/netbeans -DnetbeansSourcesDirectory='+nbbuildpath+'/build/source-zips -DnebeansJavadocDirectory='+nbbuildpath+'/build/javadoc  -Dmaven.repo.local=${env.WORKSPACE}/.repository -DparentGAV='+arelease[8]+' -DforcedVersion='+arelease[7]+' -DskipInstall=true -DdeployUrl=file://${env.WORKSPACE}/testrepo/.m2"'+"\n"
)
  mavenbuildfile.write("              }\n")
  mavenbuildfile.write("              archiveArtifacts 'testrepo/.m2/**'\n")
  mavenbuildfile.write("          }\n")
  mavenbuildfile.write("      }\n")


  write_pipelineclose(mavenbuildfile)

