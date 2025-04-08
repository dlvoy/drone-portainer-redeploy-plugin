#!/bin/bash

debug_log() {
  if [ "${PLUGIN_DEBUG}" == "true" ]; then
    if [ -t 0 ]; then
      echo "🔍 $*"
    else
      while IFS= read -r line; do
        echo "🔍 $line"
      done
    fi
  fi
} 

echo "🗂️ Searching for ${PLUGIN_STACK} in repository ${PLUGIN_URL}"

# Find stack ID and endpoint ID
STACK_INFO=$(curl -s -X GET "${PLUGIN_URL}/api/stacks" \
  -H "X-API-Key: ${PLUGIN_API_KEY}" \
  -H "Content-Type: application/json" | jq ".[] | select(.Name==\"${PLUGIN_STACK}\")")

STACK_ID=$(echo "$STACK_INFO" | jq -r ".Id")
ENDPOINT_ID=$(echo "$STACK_INFO" | jq -r ".EndpointId")
[ -z "$STACK_ID" ] && echo "❌ Stack not found!" && exit 1
[ -z "$ENDPOINT_ID" ] && echo "❌ EndpointId not found!" && exit 1

echo "🏷️ Found ${PLUGIN_STACK} stack, ID = $STACK_ID, ENDPOINT = $ENDPOINT_ID"

# Create temp files
TEMP_STACK_FILE=$(mktemp)
TEMP_BODY_FILE=$(mktemp)

# Fetch the current stack file content directly into temp file
if [ "${PLUGIN_DEBUG}" == "true" ]; then
  echo "⬇️ Downloading current stack file into $TEMP_STACK_FILE"
else
  echo "⬇️ Downloading current stack file"
fi
curl -s -X GET "${PLUGIN_URL}/api/stacks/$STACK_ID/file" \
          -H "X-API-Key: ${PLUGIN_API_KEY}" \
          -H "Content-Type: application/json" | jq -r '.StackFileContent' > "$TEMP_STACK_FILE"

if [ ! -s "$TEMP_STACK_FILE" ]; then
          echo "❌ Failed to retrieve or empty stack file content"
          rm -f "$TEMP_STACK_FILE" "$TEMP_BODY_FILE"
          exit 1
fi

if [ "${PLUGIN_DEBUG}" == "true" ]; then
  debug_log "Downloaded stack contents:"
  cat "$TEMP_STACK_FILE" | debug_log
fi

# Prepare the PUT body into another temp file
if [ "${PLUGIN_DEBUG}" == "true" ]; then
  echo "📦 Wrapping stack YAML file using $TEMP_BODY_FILE"
else
  echo "📦 Wrapping stack YAML file"
fi

#jq -n --arg yaml "$(sed -e ':a' -e 'N' -e '$!ba' -e 's/"/\\"/g' -e 's/\n/\\n/g' < $TEMP_STACK_FILE)" \
#'{"pullImage": true, "prune":true, "stackFileContent": $yaml}' > "$TEMP_BODY_FILE"
jq -n --arg yaml "$(< $TEMP_STACK_FILE)" \
'{"pullImage": true, "prune":true, "stackFileContent": $yaml}' > "$TEMP_BODY_FILE"

if [ "${PLUGIN_DEBUG}" == "true" ]; then
  debug_log "[DEBUG] stack contents embedded into JSON:"
  cat "$TEMP_BODY_FILE" | debug_log
fi

TEMP_RESPONSE_FILE=$(mktemp)

# PUT using the temp body file
echo "🔄 Reapplying the stack configuration"
response=$(curl -s -w "%{http_code}" -o $TEMP_RESPONSE_FILE -X PUT -X PUT "${PLUGIN_URL}/api/stacks/$STACK_ID?endpointId=$ENDPOINT_ID" \
          -H "X-API-Key: ${PLUGIN_API_KEY}" \
          -H "Content-Type: application/json" \
          --upload-file "$TEMP_BODY_FILE")

body=$(cat $TEMP_RESPONSE_FILE)
status=$response

debug_log "STATUS = $status"
debug_log "RESPONSE = $body"

if [ "$status" = "200" ]; then
  # Success - parse "Status" field
  stack_status=$(echo "$body" | jq -r '.Status // empty')

  if [ "$stack_status" = "1" ]; then
    echo "✅ Success! Stack is active."
  elif [ "$stack_status" = "2" ]; then
    echo "⚠️ Success, but stack is inactive."
  else
    echo "⚠️ Success, but unknown stack status: $stack_status"
  fi

else
  echo "❌ Error: HTTP $status"

  # Parse error details with jq
  error_message=$(echo "$body" | jq -r '.message // empty')
  error_details=$(echo "$body" | jq -r '.details // empty')

  echo "Message : $error_message"
  echo "Details : $error_details"

  echo "🧹 Cleaning up temp files"
  rm -f "$TEMP_STACK_FILE" "$TEMP_BODY_FILE" "$TEMP_RESPONSE_FILE"

  exit 1
fi

# Remove temp files at the end
echo "🧹 Cleaning up temp files"
rm -f "$TEMP_STACK_FILE" "$TEMP_BODY_FILE" "$TEMP_RESPONSE_FILE"