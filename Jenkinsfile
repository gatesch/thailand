def gitCommit() {
        sh "git rev-parse HEAD > GIT_COMMIT"
        def gitCommit = readFile('GIT_COMMIT').trim()
        sh "rm -f GIT_COMMIT"
        return gitCommit
    }

def answerQuestion = ''

    node {
        // Checkout source code from Git
        stage 'Checkout'
        checkout scm

	// Analyse the code for vulnerabilities using SCA
	stage 'SCA'
	sh "/opt/Fortify/Fortify_SCA_and_Apps_19.1.0/bin/sourceanalyzer -b php-safe -clean"
	sh "/opt/Fortify/Fortify_SCA_and_Apps_19.1.0/bin/sourceanalyzer -b php-safe *.php"
	sh "/opt/Fortify/Fortify_SCA_and_Apps_19.1.0/bin/sourceanalyzer -b php-safe -scan -f sample-php.fpr"
	sh "/opt/Fortify/Fortify_SCA_and_Apps_19.1.0/bin/ReportGenerator -format xml -source sample-php.fpr -f test.xml"
	sh "/opt/Fortify/Fortify_SCA_and_Apps_19.1.0/bin/ReportGenerator -format rtf -source sample-php.fpr -f test.rtf"
	sh "cp test.rtf /var/lib/jenkins"

        script {
          answerQuestion = sh (returnStdout: true, script: 'xmllint --xpath "string(//GroupingSection/@count)" test.xml')
        } 

	sh "curl -v -u admin:admin123 --upload-file test.rtf http://nexus.example.local/content/sites/safe/report`date +%F-%T`.rtf"

	echo "${answerQuestion}"

        if ( answerQuestion != "" ) {
	  echo 'SCM has some critical findings - terminating build... look at the rtf report @ http://nexus.example.local/content/sites/safe/'
	currentBuild.result = 'FAILURE'
	sh "exit ${answerQuestion}" 
	}

        // Build Docker image
        stage 'Build'
        sh "docker build -t dtr.example.local/admin/php-safe:${gitCommit()} ."

        // Login to DTR 
        stage 'Login'
        withCredentials(
            [[
                $class: 'UsernamePasswordMultiBinding',
                credentialsId: 'dtr',
                passwordVariable: 'DTR_PASSWORD',
                usernameVariable: 'DTR_USERNAME'
            ]]
        ){ 
        sh "docker login -u ${env.DTR_USERNAME} -p ${env.DTR_PASSWORD}  dtr.example.local"}

        // Push the image 
        stage 'Push'
        sh "docker push dtr.example.local/admin/php-safe:${gitCommit()}"

        // clean all
        try {
          stage('Destroy') {
                sh "export DOCKER_HOST=tcp://ucp.example.local:443 && export DOCKER_CERT_PATH=/client && export DOCKER_TLS_VERIFY=1 && docker service rm php-safe" }
}
          catch(e) {
                     build_ok = false
                     echo e.toString()
} 

        // run the container
        stage 'Deploy'
        sh "export DOCKER_HOST=tcp://ucp.example.local:443 && export DOCKER_CERT_PATH=/client && export DOCKER_TLS_VERIFY=1 && docker service create --name php-safe --network new-hrm-network --publish target=80,published=8015 --label com.docker.ucp.mesh.http=external_route=http://php-safe.example.local,internal_port=80 --dns=192.168.12.10 --constraint 'node.role == worker' dtr.example.local/admin/php-safe:${gitCommit()}"
    }
