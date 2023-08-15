// npm i @slack/webhook
import { IncomingWebhook } from '@slack/webhook'
const CHANNEL = {
  test: 'https://hooks.slack.com/services/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',
}

const webhook = new IncomingWebhook(CHANNEL['test'])

/**
 * @ECS Default
 * {
    "version": "0",
    "id": "4f96c426-bf02-25e8-76e8-820119c322a2",
    "detail-type": "CodeDeploy Deployment State-change Notification",
    "source": "aws.codedeploy",
    "account": "182024812696",
    "time": "2023-08-15T14:31:42Z",
    "region": "ap-northeast-2",
    "resources": [
        "arn:aws:codedeploy:ap-northeast-2:182024812696:deploymentgroup:todolist-codeDeploy/bluegreen-deploy",
        "arn:aws:codedeploy:ap-northeast-2:182024812696:application:todolist-codeDeploy"
    ],
    "detail": {
        "region": "ap-northeast-2",
        "deploymentId": "d-IWFN8WH80",
        "instanceGroupId": "cf406e30-d89a-47be-b8ff-c45384628d89",
        "deploymentGroup": "bluegreen-deploy",
        "state": "SUCCESS",
        "application": "todolist-codeDeploy"
    }
}

@ECS BlueGreen
{
    "version": "0",
    "id": "6d9f1df5-31f2-c0f9-32a8-951bea8743b5",
    "detail-type": "CodeDeploy Deployment State-change Notification",
    "source": "aws.codedeploy",
    "account": "182024812696",
    "time": "2023-08-15T14:32:36Z",
    "region": "ap-northeast-2",
    "resources": [
        "arn:aws:codedeploy:ap-northeast-2:182024812696:deploymentgroup:todolist-codeDeploy/bluegreen-deploy",
        "arn:aws:codedeploy:ap-northeast-2:182024812696:application:todolist-codeDeploy"
    ],
    "detail": {
        "region": "ap-northeast-2",
        "deploymentId": "d-2AC3D7I80",
        "instanceGroupId": "cf406e30-d89a-47be-b8ff-c45384628d89",
        "deploymentGroup": "bluegreen-deploy",
        "state": "START",
        "application": "todolist-codeDeploy"
    }
}
 */

export const handler = async (event) => {
  await webhook.send({
    text: JSON.stringify(event, null, 4),
  })
}
