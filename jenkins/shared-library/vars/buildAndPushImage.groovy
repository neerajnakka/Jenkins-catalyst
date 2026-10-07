// vars/buildAndPushImage.groovy -> global step
// Usage: buildAndPushImage(image: 'user/app', tag: env.GIT_SHA, context: 'nodejs-app',
//                          pushLatest: true, extraTags: [env.BUILD_NUMBER])
// Block 9 + Block 14
def call(Map config = [:]) {
    def image      = config.image   ?: error('buildAndPushImage: `image` is required')
    def tag        = config.tag     ?: env.GIT_SHA ?: env.BUILD_NUMBER
    def context    = config.context ?: '.'
    def pushLatest = config.get('pushLatest', false)
    def extraTags  = config.get('extraTags', [])

    dir(context) {
        def img = docker.build("${image}:${tag}", '--pull .')

        docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
            img.push(tag)
            extraTags.each { t -> if (t) img.push(t.toString()) }
            if (pushLatest) img.push('latest')
        }

        def digest = sh(script: "docker inspect --format='{{index .RepoDigests 0}}' ${image}:${tag}",
                        returnStdout: true).trim()
        echo "Pushed ${digest}"
        return "${image}:${tag}"
    }
}
