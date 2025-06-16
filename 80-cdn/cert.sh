#!/bin/bash

set -e

PROJECT_NAME="expense"
ENV="dev"
DOMAIN="lokeshportfo.site"
CDN_DOMAIN="$PROJECT_NAME-cdn.$DOMAIN"
PARAM_NAME="/$PROJECT_NAME/$ENV/cdn_acm_cert_arn"
ZONE_ID="Z00188163RC0DY3NOAH3R"
REGION="us-east-1"

# Step 1: Check if an ISSUED cert already exists
EXISTING_CERT_ARN=$(aws acm list-certificates \
  --region $REGION \
  --query "CertificateSummaryList[?DomainName=='$CDN_DOMAIN'].CertificateArn | [0]" \
  --output text)

if [[ "$EXISTING_CERT_ARN" != "None" && "$EXISTING_CERT_ARN" != "null" ]]; then
  STATUS=$(aws acm describe-certificate \
    --certificate-arn "$EXISTING_CERT_ARN" \
    --region $REGION \
    --query "Certificate.Status" --output text)

  if [[ "$STATUS" == "ISSUED" ]]; then
    echo "✅ Certificate already issued: $EXISTING_CERT_ARN"
    CERT_ARN="$EXISTING_CERT_ARN"
  else
    echo "⚠️ Existing certificate is not ISSUED. Requesting new one..."
    EXISTING_CERT_ARN=""
  fi
fi

# Step 2: Request new cert if not present
if [[ -z "$CERT_ARN" ]]; then
  CERT_ARN=$(aws acm request-certificate \
    --domain-name "$CDN_DOMAIN" \
    --validation-method DNS \
    --region $REGION \
    --query CertificateArn --output text)

  echo "🔐 Requested certificate: $CERT_ARN"

  # Step 3: Get DNS validation record
  sleep 5
  RECORD=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region $REGION \
    --query "Certificate.DomainValidationOptions[0].ResourceRecord" \
    --output json)

  NAME=$(echo $RECORD | jq -r .Name)
  VALUE=$(echo $RECORD | jq -r .Value)

  # Step 4: Add validation CNAME in Route53
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$NAME\",
          \"Type\": \"CNAME\",
          \"TTL\": 0,
          \"ResourceRecords\": [{ \"Value\": \"$VALUE\" }]
        }
      }]
    }"

  echo "📌 DNS record created: $NAME -> $VALUE"

  # Step 5: Wait until ISSUED
  while true; do
    STATUS=$(aws acm describe-certificate \
      --certificate-arn "$CERT_ARN" \
      --region $REGION \
      --query "Certificate.Status" \
      --output text)

    echo "🔄 Waiting for ISSUED... Current: $STATUS"

    if [[ "$STATUS" == "ISSUED" ]]; then
      echo "✅ Certificate issued!"
      break
    fi

    sleep 15
  done
fi

# Step 6: Store the final ARN in SSM
aws ssm put-parameter \
  --name "$PARAM_NAME" \
  --type "String" \
  --value "$CERT_ARN" \
  --overwrite \
  --region "$REGION"

echo "✅ Stored in SSM: $PARAM_NAME → $CERT_ARN"
