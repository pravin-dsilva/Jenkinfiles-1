properties([parameters([text(defaultValue: '''x86ub16
x86rh7
ppcub16
ppcrh7
ppcrh75''', description: '', name: 'nodelabels')]), pipelineTriggers([cron('''TZ=Asia/Kolkata
H 8 * * 4''')]), buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '15')),])

def labels = nodelabels.split("\\r?\\n")
def builders = [:]
for (x in labels) {
    def label = x
    builders[label] = {
        node(label) {
            if (label == 'ppcrh75') {
                runStages(label)
            } else {
                docker.image('base:v1').inside("-v /var/lib/jenkins/.m2/repository:/var/lib/jenkins/.m2/repository:rw,z -v /var/lib/jenkins/.ivy2:/var/lib/jenkins/.ivy2:rw,z") {
                    runStages(label)
                }
            }
        }
    }
}
def runStages(label) {
    stage('Prepare ' + label) {
        git branch: 'trunk', url: 'https://github.com/apache/pig.git'
    }
    stage('Compile ' + label) {
        sh "ant clean jar piggybank"
    }
    stage('Test ' + label) {
        try {
            sh "ant clean piggybank jar compile-test test-commit -Dtest.junit.output.format=xml"
        } catch (Exception err) {
            currentBuild.result = 'UNSTABLE'
        } finally {
            junit 'build/test/logs/TEST-*.xml'
            archive 'build/*.jar'
        }
    }
}
parallel builders
