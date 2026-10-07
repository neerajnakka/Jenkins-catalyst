// vars/runTests.groovy -> one step for both ecosystems
// Usage: runTests(type: 'node', minCoverage: 70)
//        runTests(type: 'python', minCoverage: 70)
// Block 6 + Block 14
def call(Map config = [:]) {
    def type = config.type ?: error('runTests: `type` must be "node" or "python"')
    def min  = config.get('minCoverage', 70)

    try {
        if (type == 'node') {
            sh label: 'jest', script: 'npm run test:junit'
        } else if (type == 'python') {
            sh label: 'pytest', script: ". venv/bin/activate && pytest --cov-fail-under=${min}"
        } else {
            error "Unknown project type: ${type}"
        }
    } finally {
        // publish even when tests failed -- that's the whole point of reports
        junit testResults: 'reports/junit.xml', allowEmptyResults: true
    }
}
