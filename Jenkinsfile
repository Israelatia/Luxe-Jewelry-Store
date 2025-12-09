pipeline {
    agent any
    environment {
        // הגדרת משתנים גלובליים לשימוש נוח
        AWS_ACCOUNT_ID = '992398098051'
        AWS_REGION     = 'us-east-1'
        ECR_REPOSITORY = 'aws-project'
        EKS_CLUSTER    = 'student-eks-cluster'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        # הגדרת נתיב זמני ומוגן לקובץ Kubeconfig בתוך ה-Workspace
        KUBECONFIG_PATH = "${WORKSPACE}/kubeconfig.yml" 
    }
    
    stages {
        stage('Declarative: Checkout SCM') {
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
                        withEnv(["KUBECONFIG=${KUBECONFIG_PATH}"]) {
                            
                            echo "Updating kubeconfig for EKS to use path: ${KUBECONFIG_PATH}"
                            // 1. יצירת קובץ Kubeconfig בנתיב מוגדר
                            // הפרמטר --kubeconfig מכריח את AWS CLI לכתוב לקובץ שלנו
                            bat "aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG_PATH} --alias jenkins-alias"
                            
                            echo "Testing EKS connectivity..."
                            // 2. בדיקת האימות - משתמש בקובץ Kubeconfig שיצרנו
                            bat "kubectl cluster-info" 
                            
                            echo "Applying deployment..."
                            // 3. הפעלת ה-Deployment (החלף בנתיבים ובפקודות שלך)
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
                def message = "Jenkins Build ${status}: luxe store #${BUILD_NUMBER} - ${env.BUILD_URL}"

                withAWS(region: AWS_REGION) {
                    bat "aws sns publish --topic-arn arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:jenkins-build-notifications --subject \"${subject}\" --message \"${message}\" --region ${AWS_REGION}"
                }
            }
        }
    }
}