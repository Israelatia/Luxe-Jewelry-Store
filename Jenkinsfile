pipeline {
    agent any
    
    environment {
        // הגדרת משתנים גלובליים
        AWS_ACCOUNT_ID = '992398098051'
        AWS_REGION     = 'us-east-1'
        ECR_REPOSITORY = 'aws-project'
        EKS_CLUSTER    = 'student-eks-cluster'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        // הגדרת נתיב זמני ומוגן לקובץ Kubeconfig בתוך ה-Workspace
        KUBECONFIG_PATH = "${WORKSPACE}/kubeconfig.yml" 
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                // בדיקת קוד ראשונית
                checkout scm
            }
        }
        
        stage('Build & Push Frontend') {
            steps {
                dir('frontend') {
                    // בניית תמונת Docker
                    bat "docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG} ."
                    bat "docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest"
                    
                    // התחברות ל-ECR באמצעות AWS CLI
                    withAWS(region: AWS_REGION) {
                        bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        
                        // דחיפת התמונות ל-ECR
                        bat "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}"
                        bat "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest"
                    }
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    withAWS(region: AWS_REGION) {
                        // משתנה הסביבה KUBECONFIG יחול רק בבלוק זה
                        // זה מבטיח ש-kubectl יודע היכן למצוא את הקונפיגורציה
                        withEnv(["KUBECONFIG=${KUBECONFIG_PATH}"]) {
                            
                            echo "Updating kubeconfig for EKS to use path: ${KUBECONFIG_PATH}"
                            // יצירת קובץ Kubeconfig בנתיב מוגדר בתוך ה-WORKSPACE
                            bat "aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG_PATH} --alias jenkins-alias"
                            
                            echo "Testing EKS connectivity..."
                            // בדיקת האימות. אם שלב זה נכשל, הבעיה היא בהרשאות IAM ב-EKS (aws-auth ConfigMap)
                            bat "kubectl cluster-info" 
                            
                            echo "Applying deployment..."
                            // הפעלת ה-Deployment (החלף בנתיבים ובפקודות ה-kubectl שלך)
                            bat "kubectl apply -f deployment.yaml"
                            bat "kubectl apply -f service.yaml"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            // פרסום הודעה ל-SNS על סטטוס הבנייה
            script {
                def status = currentBuild.result == 'SUCCESS' ? 'SUCCESS' : 'FAILURE'
                def subject = "Jenkins Build ${status}"
                def message = "Jenkins Build ${status}: ${env.JOB_NAME} #${BUILD_NUMBER} - ${env.BUILD_URL}"

                withAWS(region: AWS_REGION) {
                    bat "aws sns publish --topic-arn arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:jenkins-build-notifications --subject \"${subject}\" --message \"${message}\" --region ${AWS_REGION}"
                }
            }
        }
    }
}