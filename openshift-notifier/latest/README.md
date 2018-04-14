# OpenShift Notifier

This template shows how the OpenShift CLI can be used to automatically poll events and notify your team if there are `info`, `warning` or `error` events.

You can customise this template to use other messengers than Slack and Telegram.

### Installation

You can either install OpenShift Notifier via AbarCloud dashboard > Add to Project > Catalog > Other Services > OpenShift Notifier.

Or use [`oc` CLI](https://docs.abarcloud.com/management/cli-login.html):  
```sh
# For Slack notifications
oc new-app openshift-notifier.yml -p \
  SLACK_TOKEN=YOUR_SLACK_TOKEN \
  SLACK_CHANNEL=YOUR_SLACK_CHANNEL \
  NOTIFICATION_LEVEL=info

# For Telegram notifications
oc new-app openshift-notifier.yml -p \
  TELEGRAM_BOT_TOKEN=000000000:XXXXXXXXXXXXXXXXXXXXXXX \
  TELEGRAM_GROUP_ID=GROUP_NAME_OR_ID_HERE \
  NOTIFICATION_LEVEL=info
```

### Notification level

Valid `NOTIFICATION_LEVEL` values are `info`, `warning`, `error`.
If you want to update the notification level you can use:

```
oc env dc/openshift-notifier NOTIFICATION_LEVEL=warning
```

### Setup a Telegram bot

1. Visit [@BotFather](https://t.me/BotFather) bot in Telegram
2. Create a bot as [described here](https://core.telegram.org/bots#creating-a-new-bot)
3. Copy the access token `00000000:XXXXXXXXXXXXXXXXXXXXXXXXXX`
4. Find out your [group's ID](https://stackoverflow.com/a/38388851)
5. [Install notifier](#installation) as described above.

### Setup a Slack bot

1. Go to [https://my.slack.com/services/new/bot](https://my.slack.com/services/new/bot) and create a bot
2. Take note of the API token
3. Create a channel to use for your notifications and add the bot to that channel
4. [Install notifier](#installation) as described above.

### Customization
To customize notification logic or channels, please refer to [templates README.md](../../README.md). 