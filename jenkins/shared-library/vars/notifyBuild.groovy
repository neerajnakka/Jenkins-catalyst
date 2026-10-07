// vars/notifyBuild.groovy  ->  global step: notifyBuild('SUCCESS')
// Block 14 + Block 20
def call(String buildStatus = 'STARTED') {
    def color = buildStatus == 'SUCCESS'  ? 'good'    :
                buildStatus == 'UNSTABLE' ? 'warning' :
                buildStatus == 'FAILURE'  ? 'danger'  : 'good'

    def subject = "${buildStatus}: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    def summary = "${subject}\nBranch : ${env.BRANCH_NAME ?: 'n/a'}\n" +
                  "Commit : ${env.GIT_SHA ?: 'n/a'}\n${env.BUILD_URL}"

    echo summary

    // Never let a chat outage break the build
    try {
        slackSend channel: '#ci', color: color, message: summary, tokenCredentialId: 'slack-bot'
    } catch (err) {
        echo "Slack skipped: ${err.message}"
    }
}
