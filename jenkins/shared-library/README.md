# jenkins-shared-library

Groovy code shared by every pipeline. Push this to its **own** Git repository, then register it in
`Manage Jenkins → System → Global Pipeline Libraries` with the name `jenkins-shared-library`.

```
vars/     → one file = one global step   (notifyBuild, runTests, buildAndPushImage, standardPipeline)
src/      → real Groovy classes          (import com.example.ci.Versions)
resources/→ non-Groovy files             (libraryResource('scripts/smoke-test.sh'))
```

Usage from an app's Jenkinsfile:

```groovy
@Library('jenkins-shared-library@main') _
standardPipeline {
    type        = 'node'          // or 'python'
    image       = 'youruser/nodejs-app'
    context     = 'nodejs-app'
    minCoverage = 70
}
```

Pin a tag in production: `@Library('jenkins-shared-library@v1.0.0') _`.
