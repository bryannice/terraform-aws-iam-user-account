terraform {
  backend "${BACKEND_TYPE}" {
    ${BUCKET}
    ${DYNAMODB_TABLE}
    ${ENCRYPT}
    ${KEY}
    ${REGION}
  }
}