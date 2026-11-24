#! /bin/bash

set -e

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet"

display_services() {
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo
display_services
read SERVICE_ID_SELECTED

while ! [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]] || \
  ! $PSQL -c "SELECT 1 FROM services WHERE service_id = $SERVICE_ID_SELECTED;" | grep -q 1; do
  echo
  echo "I could not find that service. What would you like today?"
  display_services
  read SERVICE_ID_SELECTED
done

SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
echo
echo "What's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_ID=$($PSQL -v phone="$CUSTOMER_PHONE" <<'SQL'
SELECT customer_id FROM customers WHERE phone = :'phone';
SQL
)

if [[ -z "$CUSTOMER_ID" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_ID=$($PSQL -v phone="$CUSTOMER_PHONE" -v name="$CUSTOMER_NAME" <<'SQL'
INSERT INTO customers (phone, name) VALUES (:'phone', :'name') RETURNING customer_id;
SQL
  )
else
  CUSTOMER_NAME=$($PSQL -c "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

$PSQL -v customer_id="$CUSTOMER_ID" -v service_id="$SERVICE_ID_SELECTED" -v service_time="$SERVICE_TIME" <<'SQL'
INSERT INTO appointments (customer_id, service_id, time)
VALUES (:customer_id, :service_id, :'service_time');
SQL

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
