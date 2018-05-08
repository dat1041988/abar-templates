#!/usr/bin/env ruby

require 'json'
require 'logger'
require 'time'
require 'yaml'
require 'slack-ruby-client'
require 'telegram/bot'
require 'net/http'
require 'uri'
require 'json'

LOGGER = Logger.new(STDOUT)
ALERTMANAGER_URL = ENV['ALERTMANAGER_URL'] || ''
SLACK_TOKEN = ENV['SLACK_TOKEN'] || ''
SLACK_CHANNEL = ENV['SLACK_CHANNEL'] || ''
TELEGRAM_BOT_TOKEN = ENV['TELEGRAM_BOT_TOKEN'] || ''
TELEGRAM_GROUP_ID = ENV['TELEGRAM_GROUP_ID'] || ''
NOTIFICATION_LEVEL = ENV['NOTIFICATION_LEVEL'] || 'warning'
DB_PATH = '/var/openshift-notifier/data/db.yml'
SKIP_CONDITIONS_FILE = '/var/openshift-notifier/skip-conditions.yml'

# Let's skip the non-error ones at the moment
SKIP_CONDITIONS = YAML.load(File.read(SKIP_CONDITIONS_FILE))

COLOR_CONDITIONS = [
  [{'type' => 'Normal'}, 'good'],
  [{'type' => 'Warning'}, 'warning'],
  [{'type' => 'Error'}, 'danger'],
]

if !SLACK_TOKEN.empty?
  Slack.configure do |config|
    config.token = SLACK_TOKEN
  end

  SLACK = Slack::Web::Client.new
  SLACK.auth_test
end

if !TELEGRAM_BOT_TOKEN.empty?
  Telegram::Bot::Client.run(TELEGRAM_BOT_TOKEN) do |bot|
    TELEGRAM = bot

    chat = bot.api.get_chat(chat_id: TELEGRAM_GROUP_ID)
    TELEGRAM_CHAT_ID = chat["result"]["id"]

    TELEGRAM.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: "Notifier is started listening for events...")
  end
end

def get_last_event
  return nil unless File.exists?(DB_PATH)
  db = YAML.load(File.read(DB_PATH))
  db[:last_event] rescue nil
end

def write_last_event(event)
  File.open(DB_PATH, 'w') do |f|
    f.write(YAML.dump({
      last_event: {
        creation_timestamp: event['metadata']['creationTimestamp'],
        uid: event['metadata']['uid']
      }
    }))
  end
end

def map_color(event)
  COLOR_CONDITIONS.each do |condition, color|
    return color if condition <= event
  end
  return nil
end

def should_skip_event?(event)
  SKIP_CONDITIONS[NOTIFICATION_LEVEL].each do |condition|
    return true if condition <= event
  end
  return false
end

def send_event_notification(event)
  component = event['source']['component']
  obj_kind = event['involvedObject']['kind']
  obj_name = event['involvedObject']['name']
  first_timestamp = Time.parse(event['firstTimestamp'])
  last_timestamp = Time.parse(event['lastTimestamp'])
  color = map_color(event)

  if defined?(TELEGRAM)
    TELEGRAM.api.send_message(chat_id: TELEGRAM_CHAT_ID, parse_mode: 'markdown', text: sprintf(
      "Namespace: `%s`\n" +
      "Type: #%s\n" +
      "Object Kind: #%s\n" +
      "Object Name: `%s`\n" +
      "Reason: #%s\n" +
      "Component: `%s`\n" +
      "First timestamp: _%s_\n" +
      "Last timestamp: _%s_\n",
      event['metadata']['namespace'],
      event['type'],
      obj_kind,
      obj_name,
      event['reason'],
      component,
      first_timestamp,
      last_timestamp,
    ))
  end

  if defined?(SLACK)
    SLACK.chat_postMessage(
      channel: SLACK_CHANNEL,
      text: event['message'],
      as_user: true,
      attachments: [
        color: color,
        fields: [
          {
            title: "Namespace",
            value: event['metadata']['namespace'],
            short: true
          }, {
            title: "Type",
            value: event['type'],
            short: true
          }, {
            title: "Object kind",
            value: obj_kind,
            short: true
          }, {
            title: "Object name",
            value: obj_name,
            short: true
          }, {
            title: "Reason",
            value: event['reason'],
            short: true
          }, {
            title: "Component",
            value: component,
            short: true
          }, {
            title: "First timestamp",
            value: first_timestamp,
            short: true
          }, {
            title: "Last timestamp",
            value: last_timestamp,
            short: true
          }
        ]
      ]
    )
  end

  if !ALERTMANAGER_URL.empty?
    uri = URI.parse(sprintf("%s/api/v1/alerts", ALERTMANAGER_URL))

    header = {'Content-Type': 'application/json'}

    alerts = [
      {
        labels: {
            alertname: "Event Notifier",
            instance: sprintf("%s/%s", obj_kind, obj_name),
            namespace: event['metadata']['namespace'],
            kind: obj_kind,
            object: obj_name,
            reason: event['reason'],
            component: component,
            node: event['source']['host'],
        },
        annotations:{
            message: event['message'],
            severity: event['type'],
            summary: sprintf("%s (%s): %s", obj_kind, obj_name, event['reason'])
        },
        startsAt: event['firstTimestamp'],
        endsAt: event['lastTimestamp'],
        generatorURL: event['metadata']['selfLink'],
      }
    ]

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = alerts.to_json

    response = http.request(request)

    LOGGER.info(response)
  end
end

def poll_events
  events = `oc get events -o json`
  events = JSON.parse(events)['items']
  last_event = get_last_event
  last_index = last_event.nil? ? nil : events.find_index { |event| event['metadata']['uid'] == last_event[:uid] }
  events_to_process = last_index.nil? ? events : events[last_index + 1..-1]
  if events_to_process.empty?
    LOGGER.info("No new events to process")
  end
  events_to_process.each do |event|
    # Skip all old events
    # If the last event is no longer in the event list we still want to skip anything older than it
    next if last_event && last_event[:creation_timestamp] > event['metadata']['creationTimestamp']
    skip = false
    if should_skip_event?(event)
      skip = true
      LOGGER.info("Skipping event notification for event #{event['metadata']['uid']}: #{event['message']}")
    end
    unless skip
      LOGGER.info("Sending event notification for event #{event['metadata']['uid']}: #{event['message']}")
      begin
        send_event_notification(event)
      rescue => e
        LOGGER.error("Error sending event notification")
        LOGGER.error(e)
      end
    end
    write_last_event(event)
  end
end

while true
  LOGGER.info("==== POLLING EVENTS ====")
  poll_events
  sleep rand(60..120)
end
