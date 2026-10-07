// vars/standardPipeline.groovy
// The library owns the SHAPE; each app supplies only its details.
//
// nodejs-app/Jenkinsfile:
//   @Library('jenkins-shared-library@main') _
//   standardPipeline { type = 'node'; image = 'user/nodejs-app'; context = 'nodejs-app'; minCoverage = 70 }
//
// python-app/Jenkinsfile:
//   @Library('jenkins-shared-library@main') _
//   standardPipeline { type = 'python'; image = 'user/python-app'; context = 'python-app'; minCoverage = 70 }
def call(Map config) {
    def type    = config.type    ?: error('standardPipeline: `type` required (node|python)')
    def image   = config.image   ?: error('standardPipeline: `image` required')
    def context = config.context ?: '.'
    def min     = config.get('minCoverage', 70)
    def port    = config.get('port', type == 'node' ? 3000 : 5000)
    def runtime = type == 'node' ? 'node:20-alpine' : 'python:3.12-slim'

    pipeline {
        agent none

        options {
            timestamps()
            timeout(time: 45, unit: 'MINUTES')
            buildDiscarder(logRotator(numToKeepStr: '50', artifactNumToKeepStr: '10'))
            disableConcurrentBuilds()
        }

        stages {
            stage('Checkout') {
                agent { label 'linux' }
                steps {
                    script {
                        checkout scm
                        env.GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        currentBuild.description = env.GIT_SHA
                    }
                }
            }

            stage('Quality & Security (parallel)') {
                failFast false
                parallel {
                    stage('Build') {
                        agent { docker { image "${runtime}"; reuseNode true } }
                        steps {
                            dir(context) {
                                sh type == 'node'
                                    ? 'npm ci'
                                    : 'python -m venv venv && . venv/bin/activate && pip install -r requirements-dev.txt'
                            }
                        }
                    }
                    stage('Secret scan') {
                        agent { label 'linux' }
                        steps { sh 'gitleaks detect --source . --redact || true' }
                    }
                    stage('SCA') {
                        agent { label 'linux' }
                        steps {
                            sh 'trivy fs --scanners vuln,secret --severity HIGH,CRITICAL --ignore-unfixed --exit-code 0 . || true'
                        }
                    }
                }
            }

            stage('Test') {
                agent { docker { image "${runtime}"; reuseNode true } }
                steps { dir(context) { runTests(type: type, minCoverage: min) } }
            }

            stage('SAST · SonarQube') {
                agent { label 'linux' }
                when { anyOf { branch 'main'; branch 'develop'; changeRequest() } }
                steps {
                    dir(context) {
                        withSonarQubeEnv('sonar') { sh 'sonar-scanner' }
                    }
                }
            }

            stage('Quality Gate') {
                agent { label 'linux' }
                when { anyOf { branch 'main'; branch 'develop'; changeRequest() } }
                steps {
                    timeout(time: 5, unit: 'MINUTES') {
                        script {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') { error "Quality gate: ${qg.status}" }
                        }
                    }
                }
            }

            stage('Package, Scan & Push') {
                agent { label 'docker' }
                when { anyOf { branch 'main'; branch 'develop' } }
                steps {
                    script {
                        buildAndPushImage(image: image, tag: env.GIT_SHA, context: context,
                                          pushLatest: (env.BRANCH_NAME == 'main'),
                                          extraTags: [env.BUILD_NUMBER])
                        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed ${image}:${env.GIT_SHA}"
                        sh "syft ${image}:${env.GIT_SHA} -o cyclonedx-json=sbom.cdx.json"
                    }
                    archiveArtifacts artifacts: 'sbom.cdx.json', allowEmptyArchive: true
                }
            }
        }

        post {
            always  { script { notifyBuild(currentBuild.currentResult) } }
            cleanup { node('linux') { cleanWs() } }
        }
    }
}
