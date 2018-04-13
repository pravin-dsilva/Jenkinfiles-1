properties([parameters([text(defaultValue: '''ppcrh752''', description: '', name: 'nodelabels')]), pipelineTriggers([cron('''TZ=Asia/Kolkata
H 8 * * 4''')]), buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '15')),])

def labels = nodelabels.split("\\r?\\n")
def builders = [:]
for (x in labels) {
    def label = x
    builders[label] = {
        node(label) {
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
    }
}
parallel builders
